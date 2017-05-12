package FormValidator::Simple;
use strict;
use base qw/Class::Accessor::Fast Class::Data::Inheritable Class::Data::Accessor/;
use Class::Inspector;
use UNIVERSAL::require;
use Scalar::Util qw/blessed/;
use FormValidator::Simple::Results;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Data;
use FormValidator::Simple::Profile;
use FormValidator::Simple::Validator;
use FormValidator::Simple::Constants;
use FormValidator::Simple::Messages;

our $VERSION = '0.29';

__PACKAGE__->mk_classaccessors(qw/data prof results/);
__PACKAGE__->mk_classaccessor( messages => FormValidator::Simple::Messages->new );

sub import {
    my $class = shift;
    foreach my $plugin (@_) {
        my $plugin_class;
        if ($plugin =~ /^\+(.*)/) {
            $plugin_class = $1;
        } else {
            $plugin_class = "FormValidator::Simple::Plugin::$plugin";
        }
        $class->load_plugin($plugin_class);
    }
}

sub load_plugin {
    my ($proto, $plugin) = @_;
    my $class  = ref $proto || $proto;
    unless (Class::Inspector->installed($plugin)) {
        FormValidator::Simple::Exception->throw(
            qq/$plugin isn't installed./
        );
    }
    $plugin->require;
    if ($@) {
        FormValidator::Simple::Exception->throw(
            qq/Couldn't require "$plugin", "$@"./
        );
    }
    {
        no strict 'refs';
        push @FormValidator::Simple::Validator::ISA, $plugin;
    }
}

sub set_option {
    my $class = shift;
    while ( my ($key, $val) = splice @_, 0, 2 ) {
        FormValidator::Simple::Validator->options->{$key} = $val;
    }
}

sub set_messages {
    my ($proto, $file) = @_;
    my $class = ref $proto || $proto;
    if (blessed $proto) {
        $proto->messages(FormValidator::Simple::Messages->new)->load($file);
        if ($proto->results) {
            $proto->results->message($proto->messages);
        } else {
            $proto->results( FormValidator::Simple::Results->new(
                messages => $proto->messages,
            ) );
        }
    } else {
        $class->messages->load($file);
    }
}

sub set_message_decode_from {
    my ($self, $decode_from) = @_;
    $self->messages->decode_from($decode_from);
}

sub set_message_format {
    my ($proto, $format) = @_;
    $format ||= '';
    $proto->messages->format($format);
}

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = bless { }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, @args) = @_;
    my $class = ref $self;
    $class->set_option(@args);
    $self->results( FormValidator::Simple::Results->new(
        messages => $self->messages,
    ) );
}

sub set_invalid {
    my ($self, $name, $type) = @_;
    unless (ref $self) {
        FormValidator::Simple::Exception->throw(
            qq/set_invalid is instance method./
        );
    }
    unless ($name && $type) {
        FormValidator::Simple::Exception->throw(
            qq/set_invalid needs two arguments./
        );
    }
    $self->results->set_result($name, $type, FALSE);
}

sub check {
    my ($proto, $input, $prof, $options) = @_;
    $options ||= {};
    my $self = blessed $proto ? $proto : $proto->new(%$options);

    my $data = FormValidator::Simple::Data->new($input);
    my $prof_setting = FormValidator::Simple::Profile->new($prof);

    my $profile_iterator = $prof_setting->iterator;

    PROFILE:
    while ( my $profile = $profile_iterator->next ) {

        my $name        = $profile->name;
        my $keys        = $profile->keys;
        my $constraints = $profile->constraints;

        my $params = $data->param($keys);

        $self->results->register($name);

        $self->results->record($name)->data( @$params == 1 ? $params->[0] : '');

        my $constraint_iterator = $constraints->iterator;
        if ( scalar @$params == 1 ) {
            unless ( defined $params->[0] && $params->[0] ne '' ) {
                if ( $constraints->needs_blank_check ) {
                    $self->results->record($name)->is_blank( TRUE );
                }
                next PROFILE;
            }
        }

        CONSTRAINT:
        while ( my $constraint = $constraint_iterator->next ) {

            my ($result, $data) = $constraint->check($params);

            $self->results->set_result($name, $constraint->name, $result);

            $self->results->record($name)->data($data) if $data;
        }

    }
    return $self->results;
}

1;

=head1 NAME

FormValidator::Simple - validation with simple chains of constraints 

=head1 SYNOPSIS

    my $query = CGI->new;
    $query->param( param1 => 'ABCD' );
    $query->param( param2 =>  12345 );
    $query->param( mail1  => 'lyo.kato@gmail.com' );
    $query->param( mail2  => 'lyo.kato@gmail.com' );
    $query->param( year   => 2005 );
    $query->param( month  =>   11 );
    $query->param( day    =>   27 );

    my $result = FormValidator::Simple->check( $query => [
        param1 => ['NOT_BLANK', 'ASCII', ['LENGTH', 2, 5]],
        param2 => ['NOT_BLANK', 'INT'  ],
        mail1  => ['NOT_BLANK', 'EMAIL_LOOSE'],
        mail2  => ['NOT_BLANK', 'EMAIL_LOOSE'],
        { mails => ['mail1', 'mail2'       ] } => ['DUPLICATION'],
        { date  => ['year',  'month', 'day'] } => ['DATE'],
    ] );

    if ( $result->has_error ) {
        my $tt = Template->new({ INCLUDE_PATH => './tmpl' });
        $tt->process('template.html', { result => $result });
    }

template example

    [% IF result.has_error %]
    <p>Found Input Error</p>
    <ul>

        [% IF result.missing('param1') %]
        <li>param1 is blank.</li>
        [% END %]

        [% IF result.invalid('param1') %]
        <li>param1 is invalid.</li>
        [% END %]

        [% IF result.invalid('param1', 'ASCII') %]
        <li>param1 needs ascii code.</li>
        [% END %]

        [% IF result.invalid('param1', 'LENGTH') %]
        <li>input into param1 with characters that's length should be between two and five. </li>
        [% END %]

    </ul>
    [% END %]

example2

    [% IF result.has_error %]
    <ul>
        [% FOREACH key IN result.error %]
            [% FOREACH type IN result.error(key) %]
            <li>invalid: [% key %] - [% type %]</li>
            [% END %]
        [% END %]
    </ul>
    [% END %]

=head1 DESCRIPTION

This module provides you a sweet way of form data validation with simple constraints chains.
You can write constraints on single line for each input data.

This idea is based on Sledge::Plugin::Validator, and most of validation code is borrowed from this plugin.

(Sledge is a MVC web application framework: http://sl.edge.jp [Japanese] )

The result object this module returns behaves like L<Data::FormValidator::Results>.

=head1 HOW TO SET PROFILE

    FormValidator::Simple->check( $q => [
        #profile
    ] );

Use 'check' method. 

A hash reference includes input data, or an object of some class that has a method named 'param', for example L<CGI>, is needed as first argument.

And set profile as array reference into second argument. Profile consists of some pairs of input data and constraints.

    my $q = CGI->new;
    $q->param( param1 => 'hoge' );

    FormValidator::Simple->check( $q => [
        param1 => [ ['NOT_BLANK'], ['LENGTH', 4, 10] ],
    ] );

In this case, param1 is the name of a form element. and the array ref "[ ['NOT_BLANK']... ]" is a constraints chain.

Write constraints chain as arrayref, and you can set some constraints into it. In the last example, two constraints
'NOT_BLANK', and 'LENGTH' are set. Each constraints is should be set as arrayref, but in case the constraint has no
argument, it can be written as scalar text.

    FormValidator::Simple->check( $q => [
        param1 => [ 'NOT_BLANK', ['LENGTH', 4, 10] ],
    ] );

Now, in this sample 'NOT_BLANK' constraint is not an arrayref, but 'LENGTH' isn't. Because 'LENGTH' has two arguments, 4 and 10.

=head2 MULTIPLE DATA VALIDATION

When you want to check about multiple input data, do like this.

    my $q = CGI->new;
    $q->param( mail1 => 'lyo.kato@gmail.com' );
    $q->param( mail2 => 'lyo.kato@gmail.com' );

    my $result = FormValidator::Simple->check( $q => [
        { mails => ['mail1', 'mail2'] } => [ 'DUPLICATION' ],
    ] )

    [% IF result.invalid('mails') %]
    <p>mail1 and mail2 aren't same.</p>
    [% END %]

and here's an another example.

    my $q = CGI->new;
    $q->param( year  => 2005 );
    $q->param( month =>   12 );
    $q->param(   day =>   27 );

    my $result = FormValidator::Simple->check( $q => [ 
        { date => ['year', 'month', 'day'] } => [ 'DATE' ],
    ] );

    [% IF result.invalid('date') %]
    <p>Set correct date.</p>
    [% END %]

=head2 FLEXIBLE VALIDATION

    my $valid = FormValidator::Simple->new();

    $valid->check( $q => [ 
        param1 => [qw/NOT_BLANK ASCII/, [qw/LENGTH 4 10/] ],
    ] );

    $valid->check( $q => [
        param2 => [qw/NOT_BLANK/],
    ] );

    my $results = $valid->results;

    if ( found some error... ) {
        $results->set_invalid('param3' => 'MY_ERROR');
    }

template example

    [% IF results.invalid('param1') %]
    ...
    [% END %]
    [% IF results.invalid('param2') %]
    ...
    [% END %]
    [% IF results.invalid('param3', 'MY_ERROR') %]
    ...
    [% END %]

=head1 HOW TO SET OPTIONS

Option setting is needed by some validation, especially in plugins.

You can set them in two ways.

    FormValidator::Simple->set_option(
        dbic_base_class => 'MyProj::Model::DBIC',
        charset         => 'euc',
    );

or

    $valid = FormValidator::Simple->new(
        dbic_base_class => 'MyProj::Model::DBIC',
        charset         => 'euc',
    );

    $valid->check(...)

=head1 VALIDATION COMMANDS

You can use follow variety validations.
and each validations can be used as negative validation with 'NOT_' prefix.

    FormValidator::Simple->check( $q => [ 
        param1 => [ 'INT', ['LENGTH', 4, 10] ],
        param2 => [ 'NOT_INT', ['NOT_LENGTH', 4, 10] ],
    ] );

=over 4

=item SP

check if the data has space or not.

=item INT

check if the data is integer or not.

=item UINT

unsigined integer check.
for example, if -1234 is input, the validation judges it invalid.

=item DECIMAL

    $q->param( 'num1' => '123.45678' );

    my $result = FormValidator::Simple->check( $q => [ 
        num1 => [ ['DECIMAL', 3, 5] ],
    ] );

each numbers (3,5) mean maximum digits before/after '.'

=item ASCII

check is the data consists of only ascii code.

=item LENGTH

check the length of the data.

    my $result = FormValidator::Simple->check( $q => [
        param1 => [ ['LENGTH', 4] ],
    ] );

check if the length of the data is 4 or not.

    my $result = FormValidator::Simple->check( $q => [
        param1 => [ ['LENGTH', 4, 10] ],
    ] );

when you set two arguments, it checks if the length of data is in
the range between 4 and 10.

=item HTTP_URL

verify it is a http(s)-url

    my $result = FormValidator::Simple->check( $q => [
        param1 => [ 'HTTP_URL' ],
    ] );

=item SELECTED_AT_LEAST

verify the quantity of selected parameters is counted over allowed minimum.

    <input type="checkbox" name="hobby" value="music" /> Music
    <input type="checkbox" name="hobby" value="movie" /> Movie
    <input type="checkbox" name="hobby" value="game"  /> Game

    my $result = FormValidator::Simple->check( $q => [ 
        hobby => ['NOT_BLANK', ['SELECTED_AT_LEAST', 2] ],
    ] );

=item REGEX

check with regular expression.

    my $result = FormValidator::Simple->check( $q => [ 
        param1 => [ ['REGEX', qr/^hoge$/ ] ],
    ] );

=item DUPLICATION

check if the two data are same or not.

    my $result = FormValidator::Simple->check( $q => [ 
        { duplication_check => ['param1', 'param2'] } => [ 'DUPLICATION' ],
    ] );

=item EMAIL

check with L<Email::Valid>.

=item EMAIL_MX

check with L<Email::Valid>, including  mx check.

=item EMAIL_LOOSE

check with L<Email::Valid::Loose>.

=item EMAIL_LOOSE_MX

check with L<Email::Valid::Loose>, including mx check.

=item DATE

check with L<Date::Calc>

    my $result = FormValidator::Simple->check( $q => [ 
        { date => [qw/year month day/] } => [ 'DATE' ]
    ] );

=item TIME

check with L<Date::Calc>

    my $result = FormValidator::Simple->check( $q => [
        { time => [qw/hour min sec/] } => ['TIME'],
    ] );

=item DATETIME

check with L<Date::Calc>

    my $result = FormValidator::Simple->check( $q => [ 
        { datetime => [qw/year month day hour min sec/] } => ['DATETIME']
    ] );

=item DATETIME_STRPTIME

check with L<DateTime::Format::Strptime>.

    my $q = CGI->new;
    $q->param( datetime => '2006-04-26T19:09:21+0900' );

    my $result = FormValidator::Simple->check( $q => [
      datetime => [ [ 'DATETIME_STRPTIME', '%Y-%m-%dT%T%z' ] ],
    ] );

=item DATETIME_FORMAT

check with DateTime::Format::***. for example, L<DateTime::Format::HTTP>,
L<DateTime::Format::Mail>, L<DateTime::Format::MySQL> and etc.

    my $q = CGI->new;
    $q->param( datetime => '2004-04-26 19:09:21' );

    my $result = FormValidator::Simple->check( $q => [
      datetime => [ [qw/DATETIME_FORMAT MySQL/] ],
    ] );

=item GREATER_THAN

numeric comparison

    my $result = FormValidator::Simple->check( $q => [
        age => [ ['GREATER_THAN', 25] ],
    ] );

=item LESS_THAN

numeric comparison

    my $result = FormValidator::Simple->check( $q => [
        age => [ ['LESS_THAN', 25] ],
    ] );

=item EQUAL_TO

numeric comparison

    my $result = FormValidator::Simple->check( $q => [
        age => [ ['EQUAL_TO', 25] ],
    ] );

=item BETWEEN

numeric comparison

    my $result = FormValidator::Simple->check( $q => [
        age => [ ['BETWEEN', 20, 25] ],
    ] );

=item ANY

check if there is not blank data in multiple data.

    my $result = FormValidator::Simple->check( $q => [ 
        { some_data => [qw/param1 param2 param3/] } => ['ANY']
    ] );

=item IN_ARRAY

check if the food ordered is in menu

    my $result = FormValidator::Simple->check( $q => [
        food => [ ['IN_ARRAY', qw/noodle soba spaghetti/] ],
    ] };

=back

=head1 HOW TO LOAD PLUGINS

    use FormValidator::Simple qw/Japanese CreditCard/;

L<FormValidator::Simple::Plugin::Japanese>, L<FormValidator::Simple::Plugin::CreditCard> are loaded.

or use 'load_plugin' method.

    use FormValidator::Simple;
    FormValidator::Simple->load_plugin('FormValidator::Simple::Plugin::CreditCard');

If you want to load plugin which name isn't in FormValidator::Simple::Plugin namespace, use +.

    use FormValidator::Simple qw/+MyApp::ValidatorPlugin/;

=head1 MESSAGE HANDLING

You can custom your own message with key and type.

    [% IF result.has_error %]
        [% FOREACH key IN result.error %]
            [% FOREACH type IN result.error(key) %]
            <p>error message:[% type %] - [% key %]</p>
            [% END %]
        [% END %]
    [% END %]

And you can also set messages configuration before.
You can prepare configuration as hash reference.

    FormValidator::Simple->set_messages( {
        action1 => {
            name => {
                NOT_BLANK => 'input name!',
                LENGTH    => 'input name (length should be between 0 and 10)!',
            },
            email => {
                DEFAULT => 'input correct email address!',
            },
        },
    } );

or a YAML file.

    # messages.yml
    DEFAULT:
        name:
            DEFAULT: name is invalid!
    action1:
        name:
            NOT_BLANK: input name!
            LENGTH: input name(length should be between 0 and 10)!
        email:
            DEFAULT: input correct email address!
    action2:
        name:
            DEFAULT: ...
            
    # in your perl-script, set the file's path.
    FormValidator::Simple->set_messages('messages.yml');

DEFAULT is a special type.
If it can't find setting for indicated validation-type, it uses message set for DEFAULT.

after setting, execute check(),

    my $result = FormValidator::Simple->check( $q => [
        name  => [qw/NOT_BLANK/, [qw/LENGTH 0 10/] ],
        email => [qw/NOT_BLANK EMAIL_LOOSE/, [qw/LENGTH 0 20/] ],
    ] );

    # matching result and messages for indicated action.
    my $messages = $result->messages('action1');

    foreach my $message ( @$messages ) {
        print $message, "\n";
    }

    # or you can get messages as hash style.
    # each fieldname is the key
    my $field_messages = $result->field_messages('action1');
    if ($field_messages->{name}) {
        foreach my $message ( @{ $field_messages->{name} } ) {
            print $message, "\n";
        }
    }

When it can't find indicated action, name, and type, it searches proper message from DEFAULT action.
If in template file,

    [% IF result.has_error %]
        [% FOREACH msg IN result.messages('action1') %]
        <p>[% msg %]</p>
        [% END %]
    [% END %]

you can set each message format.

    FormValidator::Simple->set_message_format('<p>%s</p>');
    my $result = FormValidator::Simple->check( $q => [
        ...profile
    ] );

    [% IF result.has_error %]
        [% result.messages('action1').join("\n") %]
    [% END %]

=head1 RESULT HANDLING

See L<FormValidator::Simple::Results>

=head1 FLAGGED UTF-8

If you set encoding like follows, it automatically decode the
result messages.

    FormValidtor::Simple->set_mesasges_decode_from('utf-8');

=head1 SEE ALSO

L<Data::FormValidator>

http://sl.edge.jp/ (Japanese)

http://sourceforge.jp/projects/sledge

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software.
You can redistribute it and/or modify it under the same terms as perl itself.

=cut

