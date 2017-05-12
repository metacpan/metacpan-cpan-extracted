package Getopt::Yagow;
# -*-Perl-*-
# 
# DESCRIPTION
# Loads and parses command line options. See pod doc.
#  
# AUTHOR AND COPYRIGHT
# Enrique Castilla Contreras <ecastillacontreras@yahoo.es>
# Copyright (C) 2004-2007 Enrique Castilla.
#
#-----------------------------------------------------------------------
# $Id: Yagow.pm,v 1.1 2004/02/10 12:58:02 ecastilla Exp $
#-----------------------------------------------------------------------

use strict;
use vars qw( $VERSION );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

use Getopt::Long;
use Pod::Usage;

# Usage: same as load_options.
#
sub new
{
    my $class = shift;

    my $this = bless {}, $class;
    $this->load_options( @_ );

    return $this;
}

# Usage:
#    $opt = Getopt::Yagow->load_options;  or
#    $opt = Getopt::Yagow->load_options( 'option_spec' => default_value, ...)  or
#    $opt = Getopt::Yagow->load_options( { 'option_spec' => default_value, ... } ) or
#    $opt = Getopt::Yagow->load_options( { ... }, ['pass_through', ... ] );
#    
# Sample:
#
#    $p->load_options(
#           'config=s' => '',
#           'srcdir:s' => '',
#           'tardir:s' => '',
#           # 'help' => '',             # Se añade por defecto.
#           'css:s' => 'style.css',
#           'file_icon|f_icon:s' => 'c:\Perl\site\lib\tk\file.xbm',
#           'dir_icon|d_icon:s' => 'c:\Perl\site\lib\tk\folder.xbm'
#    );
#
sub load_options
{
    my $this = shift;

    my( $options_spec, $config);
    if( @_ == 2 && ref $_[0] eq 'HASH' && ref $_[1] eq 'ARRAY' )
    {
        $options_spec = $_[0];
        $config = $_[1];
    }
    elsif( @_ == 1 && ref $_[0] eq 'HASH' )
    {
        $options_spec = $_[0];
    }
    elsif( @_ >= 1 )
    {
        # Hash
        $options_spec = { @_ } if @_ ;
    }

    if( defined $config )
    {
        $this->{configuration} = $config;
        Getopt::Long::Configure( @$config );
    }

    return $this if ! defined $options_spec;

    while( my ($opt_spec,$default) = each %$options_spec )
    {
        $this->add_option( $opt_spec,$default );
    }

    return $this;
}

sub add_option
{
    my ($this, $opt_spec, $default) = @_;

    (my $opt_name = $opt_spec) =~ s/([|=:!+]).*//;
#    croak "Can't add_option '$opt_name', already defined"
#	if exists $this->{$opt_name};

    $this->{options}->{$opt_name} = $opt_spec;

    $this->{default}->{$opt_name} = $default  if defined $default;
    if( ! defined $default )
    {
        $this->{mandatory} = [] if ! exists $this->{mandatory};
        push @{$this->{mandatory}}, $opt_name ;
    }
}

sub usage
{
    my $this = shift;
    my $usage_opts = shift;

    pod2usage( $usage_opts );
}

# Usage:
#   $opt->parse_cmd_line( '--opt1 val1', '--opt2 val2', ... );
#   $opt->parse_cmd_line( ... , '--optx valx', 
#                         { -msg=>$msg_help,-verbose=>1 },
#                         { -msg=>$msg_wrong_syntax,-verbose=>0 }  );
#   $opt->parse_cmd_line( ... , '--optx valx', 
#                         { -msg=>$msg_help,-verbose=>1 }          );
#   $opt->parse_cmd_line( ... , '--optx valx', 
#                         undef,
#                         { -msg=>$msg_wrong_syntax,-verbose=>0 }  );
#
sub parse_cmd_line
{
    my $this = shift;

    my $default_msg = "!! Incorrect syntax. Use --h for help !!.\n";

    my ($i,$arg,$help_usage,$wrong_syntax);

    # Cases:
    # 1.-   ...  , {...}, {...}
    # 3.-   ...  , undef, undef
    # 4.-   ...  , {...}, undef
    # 5.-   ...  , undef, {...}
    # 6.-   ...  , undef
    # 7.-   ...  , {...}
    # 2.-   {...}, {...}
    # 8.-   undef, undef
    # 9.-   undef, {...}
    # 10.-  {...}, undef
    # 11.-  {...}
    # 12.-  undef
    #
    my $hash_no = 1;
    for( $i = 0; $i <  @_; $i++ )
    {
        $arg = $_[$i];
        if( (defined $arg && ref $arg eq 'HASH') || !defined $arg )
        {            
            if( $hash_no == 1 )
            {
                $help_usage = $arg if defined $arg; 
                $hash_no = 2;
            }

            if( $hash_no == 2 )
            {
                $wrong_syntax = $arg if defined $arg;
                $hash_no = 3;
            }        
   
            splice @_,$i,1;  # Supress $arg from argument list.
            $i--;
        }
    }

    $wrong_syntax = {-msg=>$default_msg,-verbose=>0} if ! defined $wrong_syntax;
    $help_usage =   { -verbose => 1 } if ! defined $help_usage;

    my @args = @_ ? @_ : @ARGV;
    local (@ARGV) = @args;

    #
    # Handle command line parameters
    #
    my @options = values %{ $this->{options} };
    my %used = ();
    unless( GetOptions(\%used, 'help|h|?!', @options)) 
    {
        $this->usage( $wrong_syntax );
    }

    if( exists $used{help} ) 
    {
	$this->usage( $help_usage  );
    }

    # If execution reaches this, syntax is correct from the point of view of 
    # GetOptions, but we require that options with 'undef' default value be 
    # specified in command line.
    #
    foreach my $mandatory_opt ( @{$this->{mandatory}} )
    {
        if( ! exists $used{$mandatory_opt} )
        {
            warn "There is/are mandatory argument(s)";
            $this->usage( $wrong_syntax );
        }
    }
    # Also, options with default values, but used in command line, must be
    # deleted.
    foreach ( keys %{$this->{default}} )
    {
        delete $this->{default}->{$_} if exists $used{$_};
    }
    $this->{used} = \%used;

    # Debug:
    # print "# Getopt::Yagow. \@ARGV: ",join(',',@ARGV),"\n";

    $this->{unhandled_options} = [];
    push @{$this->{unhandled_options}}, @ARGV;

    return $this;
}

sub get_configuration
{
    my $this = shift;

    return ( exists $this->{configuration} ? $this->{configuration} : [] );
}

sub get_options
{
    my $this = shift;

    return $this->{options};
}

sub get_default
{
    my $this = shift;

    return $this->{default};
}

sub get_mandatory
{
    my $this = shift;

    return $this->{mandatory};
}

sub get_used
{
    my $this = shift;

    return $this->{used};
}

sub get_unhandled
{
    my $this = shift;

    return $this->{unhandled_options};
}

sub get_options_values
{
    my $this = shift;

    return { %{$this->{default}}, %{$this->{used}} };
}

sub DEBUG
{
    my $this = shift;

    print STDERR "configuration:\n";
    foreach my $key ( @{$this->{configuration}} )
    {
        print STDERR "$key\n";
    }
    print STDERR "\n";

    print STDERR "options:\n";
    while( my($key,$val) = each %{$this->{options}} )
    {
        print STDERR "$key => $val\n";
    }
    print STDERR "\n";

    print STDERR "default:\n";
    while( my($key,$val) = each %{$this->{default}} )
    {
        print STDERR "$key => $val\n";
    }
    print STDERR "\n";

    print STDERR "mandatory:\n";
    foreach my $key ( @{$this->{mandatory}} )
    {
        print STDERR "$key\n";
    }
    print STDERR "\n";

    print STDERR "used:\n";
    while( my($key,$val) = each %{$this->{used}} )
    {
        print STDERR "$key => $val\n";
    }
    print STDERR "\n";

    print STDERR "unhandled:\n";
    foreach my $key ( @{$this->{unhandled_options}} )
    {
        print STDERR "$key\n";
    }
    print STDERR "\n";

}

__END__

=head1 NAME

Getopt::Yagow - Yet another Getopt::Long (and Pod::Usage) wrapper.

=head1 SYNOPSIS

    my $opt = Getopt::Yagow->new;
    $opt->load_options(
           'config=s' => '',
           'srcdir:s' => '',
           'tardir:s' => '',
           # 'help' => '',             # Added by default.
           'css:s' => 'style.css',
           'file_icon|f_icon:s' => 'c:\Perl\site\lib\tk\file.xbm',
           'dir_icon|d_icon:s' => 'c:\Perl\site\lib\tk\folder.xbm'
    );
    $o->parse_cmd_line;    

    # or

    my $opt = Getopt::Yagow->new(
           'config=s' => '',
           'srcdir:s' => '',
           'tardir:s' => '',
           # 'help' => '',             # Added by default.
           'css:s' => 'style.css',
           'file_icon|f_icon:s' => 'c:\Perl\site\lib\tk\file.xbm',
           'dir_icon|d_icon:s' => 'c:\Perl\site\lib\tk\folder.xbm'
    );
    $opt->parse_cmd_line( '--config configuration.file', '--css active.css', ...);
    my $opt_values = $opt->get_options_values;

    # or more compact

    my $opt = Getopt::Yagow->new( ... )->parse_cmd_line( ... );
    my $opt_values = $opt->get_options_values;

=head1 DESCRIPTION

Class wrapper of C<Getopt::Long> and C<Pod::Usage> for parsing and management
of command line options.

=head1 FUNCTIONS.

=head2 C<$opt = Getopt::Yagow-E<gt>new( [I<argument_list>] ) >

Creates a new object and returns a hash ref.
Supports same argument list as C<load_options>, because it is an abbrev of:

    my $this = bless {}, $class;
    $this->load_options( @_ );
    return $this;

So, see C<load_options> for arguments.

=head2 C<$opt = $opt-E<gt>load_options( I<argument_list> )>

Sets specification of command line arguments (passed as arguments) and prepares
for parsing.

Returns object itself.

I<argument_list> may be:

=over 4

=item *

A hash with options specifications as keys, with syntax described in C<Getopt::Long>
documentation, and default values as hash values. For example:

     $opt->load_options ( 
         'file=s' => '',
         'file_icon|f_icon|fi:s' => 'c:\Perl\site\lib\tk\file.xbm'
     ); 

=item *

A hash reference. The referenced hash is supposed to have the preceding syntax.

=item *

A hash ref and an array ref. The referenced hash with the preceding syntax, and
the referenced array must be a list of configuration options for 
C<Getopt::Long::Configure> (see doc for valid options). Sample:

     $opt->load_options ( {
               'file=s' => '',
               'file_icon|f_icon|fi:s' => 'c:\Perl\site\lib\tk\file.xbm' },
               ['require_order','pass_through'] 
     );

=back

C<load_options> creates some hash members in C<%$opt>:

=over 4

=item *

If configuration options (passed to C<Getopt::Long>) are specified, a key 
named C<configuration> is created in C<%$opt>. Its value is same array ref
passed as argument ( C<['require_order','pass_through']> in last example).

=item *

Options specifications whose default value is C<undef> are intended to be
mandatory, i.e. they MUST BE specified in command line with correct syntax. Also,
for this options specifications a C<mandatory> key is created in C<%$opt>. So,
C<$opt->{mandatory}> is an array reference of (mandatory) option names.

=item *

For options specifications whose default value is not C<undef>, an entry named
C<default> is added to C<%$opt>. So, C<$opt->{default}> is a hash ref whose keys
are option names and their values are default values taken if these options
are not specified in command line.

=item *

In any case, all options specified are stored in an entry named C<options>,
added to C<%$opt>. So, C<$opt->{options}> is a hash whose keys are options names,
and their values are options specifications.

=back

For example:

     $opt->load_options ( {
               'file1|f1=s' => undef,
               'file2=s' => '',
               'file3=s' => 'three'
                          } );

Creates three members in C<%$opt>: 

    $opt->{options} == {
                           'file1|f1=s' => undef,
                           'file2=s' => '',
                           'file3=s' => 'three'                       
                       }

    $opt->{mandatory} == ['file1']

    $opt->{default} == {
                           'file2' => '',
                           'file3' => 'three'                       
                       }

There is not a C<$opt->{configuration}> entry because there are not configuration
options specified in function call. So, don`t expect to see all mentioned entries.
Only C<options> is always present.

Mandatory options may have any option specification, not only = (but also :, !, +).

=head2 C<$opt = $opt-E<gt>parse_cmd_line( I<argument_list> )>

Parses command line arguments or arguments specified in I<argument_list>, and
returns object itself.

In case arguments to be parsed be specified in argument list, use same syntax
that were used in command line, but with each argument and associated value(s)
in between quotes. Sample:

    $opt->parse_cmd_line( '--f1=one_file.txt', '--file2=C:\icon.jpg' );

Argument list may contain one or two hash references, one for help documentation
and one for usage doc in case of wrong syntax, in this order. Both docs are
displayed via C<Pod::Usage::pod2usage>. The function acts as I<pass through>
with these last two arguments, so see doc of C<Pod::Usage> for valid options. 
In case these hash refs exists, they must be last arguments in list.

Sample:

    $opt->parse_cmd_line( '--f1=one_file.txt', '--file2=C:\icon.jpg', 
                          '--unknown=any_string',
                          {-msg => $copyrigth, -verbose => 2},         # help.
                          {-msg => $wrong_syntax, -verbose => 0}   );  # wrong syntax.

This functions adds one or two entries to C<%$opt>:

=over 4

=item *

Options used in command line or argument list are saved in C<$opt->{used}>. This
is a hash whose keys are options names, and their values are those used in
command line or function call. So, in last example:

    $opt->{used} == {
                        file1 => 'one_file.txt',
                        file2 => 'C:\icon.jpg'   
                    }

Note that option names are used as keys, not option abbreviations as specified
in command line or call to C<parse_cmd_line>.

Also, used options are deleted from C<$opt->{default}>. As a result when 
C<parse_cmd_line> returns C<$opt->{default}> contains only default values for
options not used in command line or function arguments.

=item *

If C<'pass_through'> is used in C<load_options> (or C<new>) or command line,
then unknown arguments are stored in C<$opt->{unhandled_options}>. This is an
array ref with a list of unknown arguments as specified in command line or 
function call. So, in last example:

    $opt->{unhandled_options} == ['--unknown=any_string']

=back

As a summary, all these keys may be created in C<%$opt>:

    configuration
    options
    default
    mandatory
    used
    unhandled_options

=head2 C<$arrayref = $opt-E<gt>get_configuration()>

Returns C<$opt-E<gt>{configuration}> .

=head2 C<$hashref = $opt->E<gt>get_options()>

Returns C<$opt->E<gt>{options}> .

=head2 C<$hashref = $opt-E<gt>get_default()>

Returns C<$opt-E<gt>{default}>.

=head2 C<$arrayref = $opt-E<gt>get_mandatory()>

Returns C<$opt-E<gt>{mandatory}>.

=head2 C<$hashref = $opt-E<gt>get_used()>

Returns C<$opt-E<gt>{used}>.

=head2 C<$arrayref = $opt-E<gt>get_unhandled()>

Returns C<$opt-E<gt>{unhandled_options}>.

=head2 C<$hashref = $opt-E<gt>get_options_values()>

Returns a hash reference that is the union of two hashes: key-value pairs of
C<$opt-E<gt>{used}> and key-value pairs of C<$opt-E<gt>{default}>.

=head1 SAMPLES

    my $opt = Getopt::Yagow->new;

    $opt->load_options( 
           {
               'config_file=s' => '',
               'css:s' => 'C:\Perl\html\active.css',
               'dir_icon|d_icon|di:s'  => 'c:\Perl\site\lib\tk\file.xbm',
               'file_icon|f_icon|fi:s' => 'c:\Perl\site\lib\tk\file.xbm'
           },
           ['pass_through']
    );

    $opt->parse_cmd_line split(/\s+/,'--config_file=pepe.conf --di=pepe.jpg'),  
                          {-msg => $copyright, -verbose => 2},     # help.
                          {-msg => $wrong_syntax, -verbose => 0};  # wrong syntax.

    foreach ( keys $opt->{options} )
    {
        if( exists $opt->{used}->{$_} or exists $opt->{default}->{$_})
        {
            # Argument $_ has been specified in command line or
            # is a default.

            ... (do this)
        }
        else
        {
            # Argument not used.

            ... (do that)
        }
    }

Or more compact:

    $opt = Getopt::Yagow->new(
           {
               'config_file=s' => '',
               'css:s' => 'C:\Perl\html\active.css',
               'dir_icon|d_icon|di:s'  => 'c:\Perl\site\lib\tk\folder.xbm',
               'file_icon|f_icon|fi:s' => 'c:\Perl\site\lib\tk\file.xbm'
           },
           ['pass_through']

    )->parse_cmd_line(

           split(/\s+/,'--config_file=pepe.conf --di=pepe.jpg'),  
           {-msg => $copyrigth, -verbose => 2},      # help.
           {-msg => $wrong_syntax, -verbose => 0}    # wrong syntax.       
    );

For copy, paste and experiment:

    #!/usr/local/perl -w

    # >perl samp1.pl --opt1 string [--option2 string]

    use Getopt::Yagow;

    $opt = Getopt::Yagow->new(
        'option1|opt1|o1=s' => undef, 'option2=s' => 'two'
    );

    $opt->parse_cmd_line({-verbose=>0},{-verbose=>0});

    # Si la ejecucion llega hasta aqui.
    print "There is no error in command line nor --help were used\n";

    $opt->DEBUG;

    print "get_options_values:\n";
    my $values = $opt->get_options_values();
    while( my($key,$val) = each %{ $values } )
    {
        print "$key => $val\n";
    }

    __END__

    =head1 NAME

    samp1.pl - Test for options with syntax 'option=s'.

    =head1 SYNOPSIS

        > perl samp1.pl --{option1|opt1|o1} any_string [--option2 another_string]

    =head1 OPTIONS AND ARGUMENTS

    =over 4

    =item {--option1|--opt1|--o1} string

    =item --option2 string

    =back

Also for copy, paste and experiment:

    samp2.pl
    ========

    #!/usr/local/perl -w

    # >perl samp2.pl 0|1|2 --help

    use Getopt::Yagow;

    die if $ARGV[0] != 0 && $ARGV[0] != 1 && $ARGV[0] != 2;

    my $opt = Getopt::Yagow->new->parse_cmd_line({-verbose=>$ARGV[0]},{-verbose=>$ARGV[0]});

    __END__

    =head1 NAME

    samp2.pl - Sample script for Getopt::Yagow module.

    =head1 SYNOPSIS

        % perl samp2.pl {0|1|2} --help

    =head1 DESCRIPTION

    Sample file for Getopt::Yagow module.

    =head1 OPTIONS AND ARGUMENTS

    =over 4

    =item 0 or 1 or 2

    Level of detail displaying help info.

    =item --help

    Display help info.

    =back

=head1 HINTS

=head2 Difference between C<'option'> and C<'option!'> specification.

Both specifications allows C<--option> to take no argument, and if used in command line,
corresponding hash value is assigned a boolean value: true if used incommand line and
false otherwise.

Also, second specification allows the form C<--nooption> as a sinonym of 'I<not specified in
command line>'.

For example:

     $opt->load_options ( {
               'file1'  => 1,
               'file2!' => 1
                          } );

With this option specifications, a command line with no arguments leaves 0 in both hash
values, but second allows also the syntax C<--nofile2> to do the same, while first
doesn't allow.

=head2 Options names and values separators.

There is a slithly difference when command line options are pased with C<@ARGV> and when
passed with arguments of C<parse_cmd_line>.

With C<@ARGV> each blank in command line acts as a separator of two distinct members of
C<@ARGV>. For example:

    > perl util.pl --arg1 value1 --arg2 value2

Makes 4 elements in C<@ARGV>: one for C<'--arg1'>, one for C<'value1'>, one for 
C<'--arg2'> and one for C<'value2'>. Then, C<Getopt::Long> do the rest.

From the point of view of C<Getopt::Long>, same efect is achieved using POSIX 
separators:

    > perl util.pl --arg1=value1 --arg2=value2

With arguments in C<parse_cmd_line>, same is not true:

    $opt->parse_cmd_line('--arg1 value1 --arg2 value2');

Interprets all the string as an unique option, as if only $ARGV[0] were asigned. So,
the command line syntax is incorrect becasuse C<--arg1> expects only one string and not
three. To achieve same effect, must be written as:

    $opt->parse_cmd_line('--arg1', 'value1', '--arg2', 'value2');

    or equivalently

    $opt->parse_cmd_line( @ARGV );
    
Or with POSIX separator:

    $opt->parse_cmd_line('--arg1=value1', '--arg2=value2');

Remember that any blank in command line means a separator between elements of C<@ARGV>.

=head2 Trapping syntax errors with C<$SIG{__WARN__}>

Function C<parse_cmd_line> warns and calls C<exit(...)> when syntax is wrong (in case
help usage is invoqued no warn is issued).

Warnings can be captured defining a warn handler. See tests for an example.

=head2 Do not exit programm in case of help invocation or wrong syntax.

C<pod2usage>, and also C<parse_cmd_line> in their hash refs, allows the use of
C<-exitval => 'noexit'>, meaning that program must not be terminated (C<pod2usage>
does not call C<exit>).

=head1 REQUIREMENTS

As a wrapper of C<Getopt::Long> and C<Pod::Usage>, these modules are required.

=head1 SEE ALSO.

See C<Getopt::Long> for syntax specification of command line options and
configuration in C<new> and C<load_options>.

See C<Pod::Usage> for last two optional arguments of C<parse_cmd_line>.

=head1 AUTHOR AND LICENSE

Enrique Castilla Contreras (ecastillacontreras@yahoo.es).

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 VERSION

  $Id: Yagow.pm,v 1.1 2004/02/10 12:58:02 ecastilla Exp $

