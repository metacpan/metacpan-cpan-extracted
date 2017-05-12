package FormValidator::LazyWay;

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;
use FormValidator::LazyWay::Rule;
use FormValidator::LazyWay::Message;
use FormValidator::LazyWay::Fix;
use FormValidator::LazyWay::Filter;
use FormValidator::LazyWay::Utils;
use FormValidator::LazyWay::Result;
use UNIVERSAL::require;
use Carp;
use Data::Dumper;

our $VERSION = '0.20';

__PACKAGE__->mk_accessors(qw/config unicode rule message fix filter result_class/);

sub new {
    my $class = shift;

    my $args;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }
    else {
        my %args = @_;
        $args = \%args;
    }

    croak 'you must set config' unless $args->{config};

    my $self = bless $args, $class;


    if( $args->{result_class} ) {
        $args->{result_class}->require or die $@;
        $self->{result_class} = $args->{result_class};
    }
    else {
        $self->{result_class} = 'FormValidator::LazyWay::Result';
    }

    if ( $self->unicode || $self->{config}->{unicode} ) {
        Data::Visitor::Encode->require or die 'unicode option require Data::Visitor::Encode. Please Install it.';
        my $dev = Data::Visitor::Encode->new();
        $self->config( $dev->decode('utf8', $self->config) );
    }

    my $rule = FormValidator::LazyWay::Rule->new( config => $self->config );
    my $fix  = FormValidator::LazyWay::Fix->new( config => $self->config );
    my $filter  = FormValidator::LazyWay::Filter->new( config => $self->config );
    my $message = FormValidator::LazyWay::Message->new(
        config  => $self->config,
        rule    => $rule
    );

    $self->{rule}    = $rule;
    $self->{fix}     = $fix;
    $self->{filter}  = $filter;
    $self->{message} = $message;

    return $self;
}

sub label {
    my $self = shift;
    my $lang = $self->message->lang;
    return $self->message->labels->{ $lang } ;
}

sub check {
    my $self    = shift;
    my $input   = shift;
    my %profile = %{ shift || {} };
    my $storage = {
        error_message => {} ,
        valid   => FormValidator::LazyWay::Utils::get_input_as_hash($input),
        missing => [],
        unknown => [],
        invalid => {},
        fixed   => {},
    };

    FormValidator::LazyWay::Utils::check_profile_syntax( \%profile );

    my @methods = (

        # profileを扱いやすい型にコンバート
        '_conv_profile',

        '_set_dependencies',

        '_set_dependency_groups',

        # langをプロフィールにセット
        '_set_lang',

        # デフォルトセット
        '_set_default',

        # 空のフィールドのキーを消去
        '_remove_empty_fields',

        # マージが設定された項目を storage にセット
        '_merge',

        # 未定義のフィールドをセット、そしてvalidから消去
        '_set_unknown',

        # filter ループ
        '_filter',

        # missingのフィールドをセット、そしてvalidから消去
        '_check_required_fields',

        # invalidチェックループ
        '_validation_block',

        # fiexed ループ
        '_fixed',

    );

    for my $method (@methods) {
        $self->$method( $storage, \%profile );
    }

    $storage->{has_missing} = scalar @{$storage->{missing}} ? 1 : 0 ;
    $storage->{has_invalid} = scalar keys %{$storage->{invalid}} ? 1 : 0 ;
    $storage->{has_error}   = ( $storage->{has_missing} || $storage->{has_invalid} ) ? 1 : 0 ;
    $storage->{success}     = ( $storage->{has_missing} || $storage->{has_invalid} ) ? 0 : 1 ;

    return $self->result_class->new( $storage );
}

sub _set_error_message_for_display {
    my $self           = shift;
    my $storage        = shift;
    my $error_messages = shift;
    my $lang           = shift;
    my $result         = {};

    foreach my $field ( keys %{$error_messages} ) {

        local $" = ',';
        my $tmp = "@{$error_messages->{$field}}";
        my $label = $self->message->labels->{ $lang }{ $field } || $field;
        my $mes = $self->message->base_message->{ $lang }{invalid} ;
        $mes =~ s/__rule__/$tmp/g;
        $mes =~ s/__field__/$label/g;

        $result->{$field} = $mes;
    }

    # setting missing error message
    if ( scalar @{ $storage->{missing} } ) {
        for my $field ( @{ $storage->{missing} } ) {
            my $label = $self->message->labels->{ $lang }{ $field } || $field;
            my $mes = $self->message->base_message->{ $lang }{missing} ;
            $mes =~ s/__field__/$label/g;
            $result->{$field} = $mes;
        }
    }

    $storage->{error_message} = $result;

}

sub _append_error_message {
    my $self           = shift;
    my $lang           = shift;
    my $level          = shift;
    my $field          = shift;
    my $storage        = shift;
    my $label          = shift;
    my $error_messages = shift;
    my $regex          = shift;

    $storage->{invalid}{$field}{$label} = 1;

    unless ( exists $error_messages->{$field} ) {
        $error_messages->{$field} = [];
    }

    my $key = $regex || $field ;
    push @{ $error_messages->{$field} },
        $self->message->get(
        { lang => $lang, field => $key , label => $label, level => $level }
        );

}

sub _merge {
    my $self           = shift;
    my $storage        = shift;
    my $profile        = shift;

    my @fields = keys %{ $storage->{valid} } ;

    return unless $self->config->{setting}->{merge};

    for my $key ( keys %{$profile->{required}}, keys %{$profile->{optional}} ) {
        my $field = $self->config->{setting}->{merge}->{$key};
        if ( ref $field eq 'HASH'
                 && $field->{format}
                     && $field->{fields} ) {
            my @values = map { $storage->{valid}->{$_} } @{ $field->{fields} };
            $storage->{valid}->{$key} = sprintf($field->{format}, @values);
        }
    }
}

sub _filter {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;

    my @fields = keys %{ $storage->{valid} } ;

    for my $field (@fields) {
        my $level = $profile->{level}{$field} || 'strict';
        ($storage->{valid}{$field} ) = $self->filter->parse($storage->{valid}{$field}, $level, $field);
    }
}

sub _fixed {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;

    my @fields = keys %{ $storage->{valid} } ;

    for my $field (@fields) {
        my $level = $profile->{level}{$field} || 'strict';

        my ( $v , $modified ) = $self->fix->parse($storage->{valid}{$field}, $level, $field);
        if( $profile->{use_fixed_method} && $profile->{use_fixed_method}{$field} ) {
            my $fixed_field_name = $profile->{use_fixed_method}{$field};
            $storage->{fixed}{$fixed_field_name} = $v;
        }
        else {
            $storage->{valid}{$field} = $v;
        }

    }
}

sub _validation_block {
    my $self           = shift;
    my $storage        = shift;
    my $profile        = shift;
    my $error_messages = {};

    my @fields = keys %{ $profile->{required} } ;
    push @fields , keys %{ $profile->{optional} } ;

    for my $field (@fields) {
        my $is_invalid = 0;
        my $level = $profile->{level}{$field} || 'strict';

        # missing , empty optional
        next unless exists $storage->{valid}{$field};

        # bad logic... $level may change to regex_map
        my $validators = $self->_get_validator_methods( $field, \$level );
        VALIDATE:
        for my $validator ( @{$validators} ) {

            my $stash = $profile->{stash}->{$field};

            if ( ref $storage->{valid}{$field} eq 'ARRAY' ) {

            CHECK_ARRAYS:
                for my $value ( @{ $storage->{valid}{$field} } ) {
                    if ( $validator->{method}->($value, $stash) ) {
                        # OK
                        next CHECK_ARRAYS;
                    }
                    else {
                        $self->_append_error_message( $profile->{lang},
                            $level, $field, $storage,
                            $validator->{label},
                            $error_messages , $validator->{_regex} );
                        $is_invalid++;
                        last CHECK_ARRAYS;
                    }
                }

                # 配列をやめる。
                if ( !$profile->{want_array}{ $field } ) {
                    $storage->{valid}{$field} = $storage->{valid}{$field}[0];
                    last VALIDATE;
                }

            }
            else {
                my $value = $storage->{valid}{$field};
                if ( $validator->{method}->( $value, $stash ) ) {
                    # return alwasy array ref when want_array is seted.
                    if ( $profile->{want_array}{$field} ) {
                        $storage->{valid}{$field} = [];
                        push @{ $storage->{valid}{$field} }, $value;

                    }
                }
                else {
                    $self->_append_error_message( $profile->{lang}, $level, $field, $storage, $validator->{label}, $error_messages , $validator->{_regex} );
                    $is_invalid++;
                }
            }

        }
        delete $storage->{valid}{$field} if $is_invalid;
    }

    $self->_set_error_message_for_display( $storage, $error_messages , $profile->{lang} );
}

sub _get_validator_methods {
    my $self  = shift;
    my $field = shift;
    my $level = shift;

    my $validators = $self->rule->setting->{$$level}{$field};

    if ( !defined $validators ) {

        # 正規表現にfieldがマッチしたら適応
        my @validators = ();
        foreach my $regexp ( keys %{ $self->rule->setting->{regex_map} } )
        {
            if ( $field =~ qr/$regexp/ ) {
                my @tmp = map { { %$_,_regex => $regexp } } @{$self->rule->setting->{regex_map}{$regexp}};
                push @validators,@tmp;
                $$level     = 'regex_map';
            }
        }
        if (scalar @validators) { $validators = \@validators }

        # 検証モジュールがセットされてないよ。
        croak 'you should set ' . $$level . ':' . $field . ' validate method'
            unless $validators;
    }

    return $validators;
}

sub _set_dependencies {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;
    return 1 unless defined $profile->{dependencies};

    foreach my $field ( keys %{$profile->{dependencies}} ) {
        my $deps = $profile->{dependencies}{$field};
        if (defined $storage->{valid}{$field} ) {
            if (ref($deps) eq 'HASH') {
                for my $key (keys %$deps) {
                    # Handle case of a key with a single value given as an arrayref
                    # There is probably a better, more general solution to this problem.
                    my $val_to_compare;
                    if ((ref $storage->{valid}{$field} eq 'ARRAY') and (scalar @{ $storage->{valid}{$field} } == 1)) {
                        $val_to_compare = $storage->{valid}{$field}->[0];
                    }
                    else {
                        $val_to_compare = $storage->{valid}{$field};
                    }

                    if($val_to_compare eq $key){
                        for my $dep (FormValidator::LazyWay::Utils::arrayify($deps->{$key})){
                            $profile->{required}{$dep} = 1;
                        }
                    }
                }
            }
            elsif (ref $deps eq "CODE") {
                for my $val (FormValidator::LazyWay::Utils::arrayify( $storage->{valid}{$field} )) {
                    my $returned_deps = $deps->($self, $val);

                    for my $dep (FormValidator::LazyWay::Utils::arrayify($returned_deps)) {
                        $profile->{required}{$dep} = 1;
                    }
                }
            }
            else {
                for my $dep (FormValidator::LazyWay::Utils::arrayify($deps)){
                    $profile->{required}{$dep} = 1;
                }
            }
        }
    }
}

sub __set_dependencies {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;
    return 1 unless defined $profile->{dependencies};

    foreach my $field ( keys %{ $profile->{dependencies} } ) {
        if ( $storage->{valid}{$field} ) {
            for my $dependency ( @{ $profile->{dependencies}{$field} } ) {
                $profile->{required}{$dependency} = 1;
            }
        }
    }

    return 1;
}
sub _set_dependency_groups {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;
    return 1 unless defined $profile->{dependency_groups};


    # check dependency groups
    # the presence of any member makes them all required
    for my $group (values %{ $profile->{dependency_groups} }) {
       my $require_all = 0;
       for my $field ( FormValidator::LazyWay::Utils::arrayify($group)) {
            $require_all = 1 if $storage->{valid}{$field};
       }
       if ($require_all) {
            map { $profile->{required}{$_} = 1 } FormValidator::LazyWay::Utils::arrayify($group);
       }
    }



}

sub _check_required_fields {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;

    for my $field ( keys %{ $profile->{required} } ) {
        push @{ $storage->{missing} }, $field
            unless exists $storage->{valid}{$field};
        delete $storage->{valid}{$field}
            unless exists $storage->{valid}{$field};
    }

    return 1;
}

sub _set_lang {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;

    $profile->{lang} = $profile->{lang} || $self->message->lang;
}

sub _conv_profile {
    my $self        = shift;
    my $storage     = shift;
    my $profile     = shift;
    my %new_profile = ();
    %{ $new_profile{required} } = map { $_ => 1 }
        FormValidator::LazyWay::Utils::arrayify( $profile->{required} );
    %{ $new_profile{optional} } = map { $_ => 1 }
        FormValidator::LazyWay::Utils::arrayify( $profile->{optional} );
    %{ $new_profile{want_array} } = map { $_ => 1 }
        FormValidator::LazyWay::Utils::arrayify( $profile->{want_array} );

    $new_profile{stash} = $profile->{stash};

    %{$profile} = ( %{$profile}, %new_profile );

    return 1;
}

sub _set_unknown {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;

    @{ $storage->{unknown} } = grep {
        not(   exists $profile->{optional}{$_}
            or exists $profile->{required}{$_} )
    } keys %{ $storage->{valid} };

    # and remove them from the list
    for my $field ( @{ $storage->{unknown} } ) {
        delete $storage->{valid}{$field};
    }

    return 1;
}

sub _set_default {
    my $self    = shift;
    my $storage = shift;
    my $profile = shift;

    # get from profile
    my $defaults = $profile->{defaults} || {};
    foreach my $field ( %{ $defaults } ) {
        unless (defined $storage->{valid}{$field}) { $storage->{valid}{$field} = $defaults->{$field} }
    }

    # get from config file
    if ( defined $self->rule->defaults ) {
        foreach my $field ( keys %{ $self->rule->defaults } ) {
            $storage->{valid}{$field} ||= $self->rule->defaults->{$field};
        }
    }


    return 1;
}

sub _remove_empty_fields {
    my $self    = shift;
    my $storage = shift;
    $storage->{valid} = FormValidator::LazyWay::Utils::remove_empty_fields(
        $storage->{valid} );

    return 1;
}

sub add_custom_invalid {
    my $self = shift;
    my $form = shift;
    my $key  = shift;
    my $message
        = $self->{messages}{config}{messages}{ $form->lang }{custom_invalid}
        {$key} || $key;
    $form->custom_invalid( $key, $message );
}

1;

__END__

=head1 NAME

FormValidator::LazyWay - Yet Another Form Validator

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Data::Dumper;
    use CGI;
    use FormValidator::LazyWay;
    
    my $config = {
        'setting' => {
            'strict' => {
                'email'    => { 'rule' => [ 'Email#email' ] },
                'password' => {
                    'rule' => [
                        {   'String#length' => {
                                'min' => '4',
                                'max' => '12'
                            }
                        },
                        'String#ascii'
                    ]
                }
            }
        },
        'lang'   => 'en',
        'labels' => {
            'en' => {
                'email'    => 'mail address',
                'password' => 'password'
            }
        },
        'rules' => [ 'Email', 'String' ]
    };
    
    my $fv  = FormValidator::LazyWay->new(config => $config);
    my $cgi = new CGI( { password => 'e' } );
    my $res = $fv->check( $cgi, { required => [qw/email password/], } );
    
    if ( $res->has_error ) {
        print Dumper $res->error_message;
        # output  
        #$VAR1 = {
        #  'email' => 'mail address format is missing.',
        #  'password' => 'password minimun 4 letters and maximum 12 letters',
        #};
    }
    else {
    
        # OK!
        print Dumper $res->valid;
    }
    
=head1 DESCRIPTION

THIS MODULE IS UNDER DEVELOPMENT. SPECIFICATION MAY CHANGE.

This validator's scope is not a form but an application. why?? 
I do not like a validator much which scope is a form because I have to write rule per form.  that make me tired some. 

this module lets you write rule per field and once you set those rule what you need to worry is only required or optional for basic use.
One note. Since you set rule per filed , your can not name like 'message' which may have 30 character max or 50 character max depend where you store.
I mean you should name like 'inquiry_message'(30 character max) , 'profile_message'(50 character max) if both rule is different.

There is one more cool aim for this validator. this validator does error message staff automatically. 

well I am not good at explain all about detail in English , so I will write some code to explain one by one.

=head1 QUICK START

Let's start to build a simple inquiry form .

=head2 CONFIG SETTING 

For this sample , I am using YAML. but you can use your own way.
OK, I am using two rule modules in this case.
detail is here L<FormValidator::LazyWay::Rule::Email> L<FormValidator::LazyWay::Rule::String> 

    rules :
        - Email
        - String
    lang : en
    setting :
        strict :
            email :
                rule :
                    - Email#email
            message :
                rule :
                    - String#length :
                        min : 1
                        max : 500
            user_key :
                rule :
                    - String#length :
                        min : 4
                        max : 12
                    - String#ascii 
    labels :
        ja :
            email    : email address
            message  : inquiry message
            user_key : user ID

=head2 PREPARE 

For first step , you need to create FormValidator::LazyWay object. 
What all you need is , just pass config data.

    use FormValidator::LazyWay;
    use YAML::Syck;
    use FindBin;
    use File::Spec;

    my $conf_file = File::Spec->catfile( $FindBin::Bin, 'conf/inquiry-sample.yml' );
    my $config = LoadFile($conf_file);
    my $fv = FormValidator::LazyWay->new( config => $config );

=head2 HOW TO CHECK 

CASE : you want email and message for sure. and user_key is optional.

    my $cgi = new CGI() ; # contain posted data

    my $res = $fv->check( $cgi , {
        required => [qw/email message/],
        optional => [qw/user_key/],
    });

    # when error
    if( $res->has_error ) {
        warn Dumper $res->error_message;
    }
    # OK!
    else {
        warn Dumper $res->valid;
    }

=head2 RESULT

=over

=item SUCCESS
 
    my $cgi = new CGI( { email => 'tomohiro.teranishi@gmail.com' , use_key => 'tomyhero' , message => 'this data work' } ) ;

$res->valid Dumper result

    $VAR1 = {
        'email' => 'tomohiro.teranishi@gmail.com',
        'message' => 'this data work'
    };


=item MISSING
 
    my $cgi = new CGI( { message => 'does not work' } ) ;

$res->error_message Dumper Result

    $VAR1 = {
        'email' => 'email address is missing.'
    };

=item INVALID

    my $cgi = new CGI( { email => 'email' , use_key => 'tom' , message => 'does not work!'  } ) ;

$res->error_message Dumper result

    $VAR1 = {
        'email' => 'email address supports email address format'
    };

=back

=head1 CONFIG

=head2 rules

You must set which rule module you want to use. 

If you want to use L<FormValidator::LazyWay::Rule::String> then type 'String'.
and I you want to use your own rule module then, start with + SEE Blow e.g.

 rules :
    - String
    - +OreOre::Rule

=head2 lang

you need to set which lang you want to use for default. default value is en.

 lang : ja

=head2 langs

If you want to use several languages then listed them or you do not need to worry.

 langs : 
    - ja
    - en

=head2 setting

setting format specific.

 setting :
    'level' :
    'field name' :
        'type' :
            'type data'

=over 

=item level 


When you want to use have couple rules for a field, you can use 'level' setting.
default level is 'strict';

e.g. 

your register form use 'strict' level , and use 'loose' for your fuzzy search form .

 setting :
    strict : 
        email :
            rule :
                - Email#email
    loose :
        email :
            rule :
                - Email#much_alias
 

CASE register form does not need to set level because 'strict' is default level.

    my $res = $fv->check( $cgi , { required => [qw/email/] } );

CASE fuzzy search form , you should set 'loose' for level.

    my $res = $fv->check( $cgi , { required => [qw/email/] , level => { email => 'loose' }   } );

And also level has two special levels.

one is 'regex_map' . 
when you use this level , you can use regular exp for field name.

 setting :
    regexp_map :
        '_id$' :
            rule :
                - Number#int
    strict :
        foo_id :
            rule :
                - Email#email
        

If you set like this , then all ***_id field use Number#int rule. and regexp_map priority is low so if you set foo_id for 'strict' level,
then the rule is used for foo_id(not _id$ rule)

the other special level is 'merge'

Using this module , you can merge several fields and treat like a field.

  merge:
    date:
      format: "%04d-%02d-%02d"
      fields:
        - year
        - month
        - day
  strict:
    date:
      rule:
        - DateTime#date

=item field name

you can set field name.

=item type

rule, filter and fix is supported.

=over

=item rule 

mapping between field name and rule module. 

 rule :
    - String#length :
        min : 4
        max : 12
    - String#ascii
    - +OreOre#rule

=item filter

mapping between field name and filter module.

filter run before rule check and modify parameter what you want.
e.g.  decoding name value before rule run.

  name :
    rule :
      - String#length:
          min : 4
          max : 12
    filter :
      - Encode#decode:
          encoding: utf8

=item fix

mapping between field name and fix module.
fix module lets you fix value after rule check.

e.g. fix String Date Format to DateTime Object.

  date:
    rule:
      - DateTime#date
    fix:
      - DateTime#format:
          - '%Y-%m-%d'

=back

=back 

=head2 labels

setting field name labels.

 labels :
    en :
        email     : Email Address 
        user_name : User Name
        user_id   : User ID

this labels are used for error message.

=head2 messages

Only if you want to overwrite message, then use this setting.

    messages :
        ja :
            rule_message : __field__ supports __rule__, dude.
            rule :
                Email#email  : EMAIL
                String#length : $_[min] over, $_[max] upper


=head1 PROFILE 

call 'profile' for second args for check method.

=head2 required

set required field name. if not found these field, then missing error occur.

 my $profile 
    = {
        required => [qw/email name/],
    }

=head2 optional

set optional field name. this filed can be missing.

 my $profile 
    = {
        optional => [qw/zip/],
    }

=head2 defaults

you can specify default value. this default value is set if value is empty before required check run.

 my $profile 
    = {
        required => [qw/email name/],
        defaults => {
            email => 'tomohiro.teranishi@gmail.com',
            name => 'Tomohiro',
        },
    }


=head2 want_array

if you want to have plural values for a field, then you must set the field name for want_array. 
if you use this then $valid->{hobby} has array ref (even one value)

 my $profile 
    = {
        required => [qw/email name/],
        optional => [qw/hobby/],
        want_array => [qw/hobby/],
    }

=head2 lang

you can change lang which can be listed at langs setting at config data.

 my $profile 
    = {
        required => [qw/email name/],
        lang => 'ja',
    }

=head2 level

you can change level if you like.

 my $profile 
    = {
        required => [qw/email name/],
        level => {
            email => 'loose',
            name  => 'special',
        }
    }

=head2 dependencies

you can make a item that needs other items.
Example of setting the following: delivery option is needed address_for_delivery and name_for_delivery.

 my $profile 
    = {
        required => [qw/name address/],
        dependencies => {
           delivery => {
               1 => [qw/address_for_delivery name_for_delivery/]
           }
        }
    }

=head2 use_fixed_method

you can get your fixed valid data from fixed() instead of valid(). valid() hold none fixed values.

 my $profile = {
    required => [qw/date/],
    use_fixed_method => { 
        date => 'date_obj', 
    },
 };

 $res->valid('date'); # raw data
 $res->fixed('date_obj'); #fixed obj
 

=head1 RESULT

  my $res = $fv->check( $cgi , $profile ) ;
 
$res is L<FormValidator::LazyWay::Result> object. SEE L<FormValidator::LazyWay::Result> POD for detail.

=head1 HOW TO

=head2 how to use L<FormValidator::LazyWay::Result> subclass.

you can set your subclass name like bellow.

 my $fv = FormValidator::LazyWay->new( { config => $block->config , result_class => 'YourResult' } ); 

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

Daisuke Komatsu <vkg.taro@gmail.com>

=cut

