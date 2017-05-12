package Getopt::Param;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.5');

use Locale::Maketext::Pseudo;
use Class::Std;
use Class::Std::Utils;

{   
    my %lang;
    my %opts;
    my %quiet;
    my %args_ar;
    my %help_cr;

    sub BUILD {
        my ($prm, $ident, $arg_ref) = @_;
        
        $lang{ $ident } = ref $arg_ref->{'lang_obj'} && $arg_ref->{'lang_obj'}->can('maketext') 
            ? $arg_ref->{'lang_obj'} : Locale::Maketext::Pseudo->new();
        
        $opts{ $ident }    = {};
        $quiet{ $ident }   = $arg_ref->{'quiet'} || 0;        
        my $args_ar        = ref $arg_ref->{'array_ref'} ne 'ARRAY' ? \@ARGV : $arg_ref->{'array_ref'};
        my @nodestruct     = @{ $args_ar };
        $args_ar{ $ident } = \@nodestruct;

        my $idx = 0;
        ARG_ITEM:
        for my $arg ( @{ $args_ar{ $ident } } ) {
            last ARG_ITEM if $arg eq '--';
            
            my $rg = $arg_ref->{'strict'} ? qr{^--([^-])} : qr{^--(.)};
            
            if( $arg =~ s/$rg/$1/ ) {
                my($flag, $value) = split /=/, $arg, 2;
                push @{ $opts{ $ident }->{ $flag } }, defined $value ? $value : '--' . $flag;
            }
            else {
                carp $lang{ $ident }->maketext('Argument [_1] did not match [_2]', $idx, $rg) if !$quiet{ $ident };
            }
            $idx++;
        }
        
        if ( $opts{ $ident }->{'help'} && $arg_ref->{'help_coderef'} ) {
            $arg_ref->{'help_coderef'}->($prm);
        }
        
        $help_cr{$ident} = $arg_ref->{'help_coderef'} || sub { croak $lang{ $ident }->maketext(q{No '[_1]' function defined}, 'help') };

        if ( !keys %{$opts{$ident}} && $arg_ref->{'no_args_help'} ) {
            $help_cr{$ident}->($prm);
        }
        
        if( ref $arg_ref->{'known_only'} eq 'ARRAY') {
            my %lookup;
            @lookup{ @{$arg_ref->{'known_only'}} } = ();
            
            my $unknown = 0;
            for my $k (keys %{$opts{$ident}}) {
                if (!exists $lookup{$k}) {
                    $unknown++;
                    # $k =~ s{\W}{?}g; # or quotemeta()
                    carp $lang{ $ident }->maketext(q{Unknown argument '[_1]'}, quotemeta($k));
                }
            }
            $help_cr{$ident}->($prm) if $unknown;
        }
        
        if( ref $arg_ref->{'required'} eq 'ARRAY') {
            
            my $missing = 0;
            for my $k (@{$arg_ref->{'required'}}) {
                if (!exists $opts{$ident}->{$k}) {
                    $missing++;
                    # $k =~ s{\W}{?}g; # or quotemeta()
                    carp $lang{ $ident }->maketext(q{Missing argument '[_1]'}, quotemeta($k));
                }
            }
            $help_cr{$ident}->($prm) if $missing;
        }
        
        if( ref $arg_ref->{'validate'} eq 'CODE') {
            $arg_ref->{'validate'}->($prm) || $help_cr{$ident}->($prm);
        }
        
        if ( ref $arg_ref->{'actions'} eq 'ARRAY' ) {
            for my $k ($arg_ref->{'actions'}) {
                if (exists $opts{$ident}->{$k->[0]}) {
                    if (ref $k->[1] eq 'CODE') {
                        $k->[1]->($prm);
                    }
                    else {
                        $help_cr{$ident}->($prm);
                    }
                }
            }
        }
    }

    sub help {
        my ($prm) = @_;
        $help_cr{ ident $prm }->();
    }

    sub get_param {
        my ($prm, $name) = @_;
        return if !exists $opts{ ident $prm }->{ $name }; # do not auto vivify it
        $opts{ ident $prm }->{ $name } = [] if ref $opts{ ident $prm }->{ $name } ne 'ARRAY';
        return wantarray ? @{ $opts{ ident $prm }->{ $name } } 
                         : $opts{ ident $prm }->{ $name }->[0];
    }
   
    sub set_param {
        my ($prm, $name, @val) = @_;
        $opts{ ident $prm }->{ $name } = [ @val ];
            # = ref $val->[0] eq 'ARRAY' && @val == 1 ? [ @{ $val->[0] } ] : [@val];
    }

    sub list_params {
        my ($prm) = @_;
        return wantarray ? keys %{ $opts{ ident $prm } }
                         : [ keys %{ $opts{ ident $prm } } ]
                         ;    
    }

    sub append_param {
        my ($prm, $name, @val) = @_;
        $opts{ ident $prm }->{ $name } = [] if ref $opts{ ident $prm }->{ $name } ne 'ARRAY';
        $opts{ ident $prm }->{ $name } = [ @{ $opts{ ident $prm }->{ $name } }, @val ];
    }
 
    sub prepend_param {
        my ($prm, $name, @val) = @_;
        $opts{ ident $prm }->{ $name } = [] if ref $opts{ ident $prm }->{ $name } ne 'ARRAY';
        $opts{ ident $prm }->{ $name } = [ @val, @{ $opts{ ident $prm }->{ $name } } ];
    }

    sub param {
       my ($prm, $name, @val) = @_;
       return $prm->list_params() if !$name;
       $prm->set_param( $name, @val ) if @val;
       return $prm->get_param( $name );
    }   

    sub delete_param {
        my ($prm, $name) = @_;    
        delete $opts{ ident $prm }->{ $name };
    }

    sub exists_param {
        my ($prm, $name) = @_;
        return 1 if exists $opts{ ident $prm }->{ $name };
        return;
    }

    sub get_param_hashref {
        my ($prm) = @_;
        my %new_hash = %{ $opts{ ident $prm } };
        return \%new_hash; # deref first so the internal one does not risk ferdidling
    } 
}

1; 

__END__

=head1 NAME

Getopt::Param - param() style opt handling

=head1 VERSION

This document describes Getopt::Param version 0.0.5

=head1 SYNOPSIS

    use Getopt::Param;
    my $prm = Getopt::Param->new(...);

    $prm->help() if $prm->get_param('number') !~ m{\A\d+\z}xms; # --help, see 'help_coderef' new() key
    
    $log->debug( "Start: $$ " . time() ) if $prm->get_param('debug'); # --debug
   
    print "Starting process...\n" if $prm->get_param('verbose'); # --verbose

    do_this();
  
    do_that() if that_is_needed() || $prm->get_param('force'); # run this regardless if --force
    
    do_theother() if $prm->get_param('theother'); # --theother
    
    print "...Done!\n" if $prm->get_param('verbose'); # --verbose
    
    $log->debug "End: $$ " . time() ) if $prm->get_param('debug'); # --debug 

    $lang->say(q{User '[1]' has been setup with the name '[2]'}, $prm->param('user'), $prm->param('name')); # --user=dan --name="Dan Muey"

=head1 DESCRIPTION

Parses an array and gives it a CGI-like param interface to the data. You can then have apps that have a cgi interface and a cli interface that just call param() to get its stuff.

Examples:

  Opt: --force=1 URI Equiv: force=1
  Opt: --force=  URI Equiv: force=
  Opt: --force   URI Equiv: force=--force
  Opt: --force=hello         URI Equiv: force=hello
  Opt: --force="hello world" URI Equiv: force=hello+world
  Opt: --force=a --force=b   URI Equiv: force=a&force=b

=head1 INTERFACE

=begin comment

=over

=item BUILD()

=back

=end comment

=over

=item new()

Can take no arguments or one hashref whose keys are desribed below (non are required)

=over 4

=item array_ref

The array to get the params from, defaults to @ARGV if none is given. 

Note: No array's are harmed inthe making of this object.

Note: An item of '--' marks the end of parameter processing like in a shell

=item lang_obj

A language object that can() maketext(), see "LOCALIZATION" below and L<Locale::Maketext::Pseudo>

=item strict

Boolean that when true means that each option must start with two '-' and then a non dash character (or else its ignored)

   --good ---bad

When its false as long as it starts with two '-' then its ok:

   ---allowed --good

in that case your param() name will be '-allowed' not 'allowed'

=item quiet

Boolean that when true supresses the FYI about invalid options in the array.

=item help_coderef

This gets executed if the param 'help' exists (IE --help), by the help() method, and under other circumstance described in the POD.

The object is passed in as its argument.

=item no_args_help

If this is true and no arguments are given your help_coderef is executed. If you did not specify a 'help_coderef' you'll get an error about that instead.

=item known_only

Array reference of all known flags, if unknown flags are passed a warning is issued and the help function is called.

=item required

Array reference of all required flags, if any are not passed warning is issued and the help function is called.

=item validate

A code reference that gets passed the object, you can do any checking you like. 

A good idea is to carp about any problems and return; 

Returning false will trigger help

=item actions

An array reference containing array references where item 0 is the flag and item 1 is a code ref to execute (or if not a code ref then help wil be done)

    'actions' => [
        ['usage', 1], # help alias
        ['perldoc', sub {...}],
        ['man', sub {...}],
        ['bincheck', sub { print "Binary ok!";exit; } ],
    ]

Like help, each of these is a passed the object.

=begin comment

<< part of TODO >>

=item short_opts

A hashref that tells it what short args may be present.

A "short opt" is one dah and one letter and it must be followed by a value to be assigned to it:

   -u username
   
*or* your coderef (see below) must recognize that the value is not supposed to be assigned to it:

  -u username -p --force
 
or
  -u username -p
  
or

  -p -u username

The key is the short arg's name.

The value is a coderef that gets the $object and the item that is *after* the key in the array.

It should return the param name to assign the value to and if it should be skipped simply 'return;'


  '-u' => sub {
          my($prm, $next_items_value) = @_;
          return 'param_name' if whatever( $value )
          return;  
     },

=item positional_opts

hashref that tells it what postional args may be present:

The key is the index of the items position in the array.

The value is a coderef that gets the $object and the item in that position as its arguments.

It should return the param name to assign the value to and if it shoud be skipped simply 'return;'

   '0' => sub {
        my($prm, $value) = @_;
        return 'param_name' if whatever( $value )
        return;  
   },
   '1' => sub {
       my($prm, $value) = @_;
       return 'param_foo' if whatever( $value );
       return 'param_bar ? if everwhat( $value );
       $prm->set_param('help', 1); # sine its neither send them to help
       return;
   },

=end comment

=back

=item param()

Acts like the get/set param you are used to in CGI based object's param() and when called with no args returns a list of param names available.
When creating a generic "param" obj for use by an app that is CGI and CLI aware you may be stuck doing this multi function param() but if possible I'd recommend using the specific ones and creating a class method that wraps them:

   sub get_param {
       my ($self, $name) = @_;
       $self->{'param_obj'} = $self->can('get_param') ? $self->{'param_obj'}->get_param( $name )
                                                      : $self->param( $name )
                                                      ;
   } 

That allows you to use a non ambiguous get_param everywhere in your app regardless of what the param_obj actually needs to do.

=item set_param()

Sets the param named as the first arg to the value(s) of the rest of the args:

   $prm->set_param('name', 'v1', 'v2', 'etc');

=item get_param()

    my $name  = $prm->get_param('name');
    my @names = $prm->get_param('name');

=item list_params()

Returns all available param names, like calling param() with no arguments:

    for my $param ( $prm->list_params() ) {
        print "1st $param is: " . $prm->param( $param ) . "\n";
    }

=item append_param()

Like set_param() but puts values after existing values (if any).

=item prepend_param()

Like set_param() but puts values before existing values (if any).

=item delete_param()

Deletes the given param name from the param data, returns its current values in an arrayref.

    # $prm->exists_param('name') is true
    my $dog_arrayref = $prm->delete_param('dog');
    # $prm->exists_param('name') is false 

=item exists_param()

Returns true if there was a param of that "name" passed

    if( $prm->exists_param('name') ) {
        ...
    }

=item get_param_hashref()

Returns a serializable hashref of the param's and their values (in array refs)

=item help()

Executes the object's help coderef. If you did not specify a 'help_coderef' you'll get an error about that instead.

=back

=head1 DIAGNOSTICS

=over

=item C<< Argument %d did not match %s >>

This is just a sort of FYI that the array had a value ( at index '%d') that 
did not start with the regex ('%s') that detemrines if an argument was an 
option or not and therefore will be ignored

The regex is based on your 'strict' key value [not ]passed to new() .

This can be supressed by passing new() 'quiet' => 1

=item C<< No '%s' function defined >>

Something has triggered a coderef as per your new() args but the given coderef was not defined in new.

=item C<< Unknown argument '%s' >>

'known_only' was set and an argument that was not in that list was passed.

=item C<< Missing argument '%s' >>

'required' was set and one or more of those flags were not passed.

=back

=head1 LOCALIZATION

This module uses L<Locale::Maketext::Pseudo> as a default if nothing else is 
specified to support localization in harmony with the apps using it.

See "DESCRIPTION" at L<Locale::Maketext::Pseudo> for more info on why this is 
good and why you should use this module's language object support at best and, 
at worst, appreciate it being there for when you will want it later.


=head1 CONFIGURATION AND ENVIRONMENT
  
Getopt::Param requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Class::Std>, L<Class::Std::Utils>, L<Locale::Maketext::Pseudo>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-getopt-param@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

- (This was a comment in BUILD()'s code) allowed/required/description hr + auto help_coderef generation ?  Getopt::Param::Config ?

- Short option (-u user instead of --user=user) support

- Positional option support

For now if you want to have some positional args or args that are otherwise not --long switches:

  # 1) use 'quiet' in your construtor
  # 2) parse the array in question and set_param() as per your needs:
  
  use Getopt::Param;
  my $prm = Getopt::Param->new({ 'quiet' => 1 });
  
  $prm->set_param('revision', $ARGV[0]) if $ARGV[0] =~ m{^\d+$};
  
  my $idx = 0;
  for my $arg (@ARGV) {
      if( $arg eq '-r' ) {
          $prm->set_param('revision', $ARGV[ $idx + 1]):
      }
      $idx++;
  }

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
