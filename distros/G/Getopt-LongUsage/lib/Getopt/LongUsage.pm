package Getopt::LongUsage;

use 5.008001;
use strict;
use warnings;
use Exporter;
use Carp;
use Getopt::Long 2.37;
use Data::Dumper;

BEGIN {
    use vars      qw(@ISA @EXPORT @EXPORT_OK);
    @ISA        = qw(Exporter);
    @EXPORT     = qw(&GetLongUsage);
    @EXPORT_OK  = qw(&GetLongUsage);

    use vars      qw($REF_NAME);
    $REF_NAME   = "Getopt::LongUsage";  # package name

    use vars      qw( $VERSION );
    $VERSION    = '0.12';
}


# new
sub new {
    my $pkg	= shift;
    my $class	= ref($pkg) || $pkg;
    my $self	= bless {}, $class;
    return $self;
}


sub ParseGetoptLongConfig (@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my @optionlist  = @_;
    my $opctl   = {};
    my $error   = '';

    # Since we are reading a configuration for Getopt::Long, we have to do some
    # of the same things as that module, however we do not need all the same
    # resulting information, so we will shift the unneeded stuff into oblivion

    # from Getopt::Long
    # Check for ref HASH as first argument.
    # First argument may be an object.
    if ( @optionlist &&
         ref($optionlist[0]) &&
         UNIVERSAL::isa($optionlist[0],'HASH') ) {
        shift @optionlist;
    }

    # from Getopt::Long
    # See if the first element of the optionlist contains option
    # starter characters.
    # Be careful not to interpret '<>' as option starters.
    # for Getopt::LongUsage
    # This is where Getopt::Long defined the $prefix as a regex
    if ( @optionlist &&
         $optionlist[0] =~ /^\W+$/ &&
	     !( $optionlist[0] eq '<>' &&
	        @optionlist > 0 &&
	        ref($optionlist[1])) ) {
        shift (@optionlist);
    }

    # from Getopt::Long
    # Verify correctness of optionlist.
    while (@optionlist) {
        my $opt = shift (@optionlist);

        unless ( defined $opt ) {
            $error .= "Undefined argument in option spec\n";
            next;
        }

        # from Getopt::Long
        # Strip leading prefix so people can specify "--foo=i" if they like.
        # $opt = $+ if $opt =~ /^$prefix+(.*)$/s;
        # for Getopt::LongUsage
        # We are not honoring $prefix in the configuration option list.
        # the option list should not contain prefixes, just the option name
        # i.e., configure with 'debug|d:i' and not '--debug|-d:i'
        # I guess it could be added in if requested
        # This is the globally Getopt::Long configured $prefix value

        # from Getopt::Long
        # Parse option spec.
        my ($name, $orig) = Getopt::Long::ParseOptionSpec($opt,$opctl);
        unless ( defined $name ) {
            # Failed. $orig contains the error message. Sorry for the abuse.
            $error .= $orig;
        }
        shift (@optionlist) if @optionlist && ref($optionlist[0]);
    }
    return $opctl;
}


# GetLongUsage
#
# TODO - add support for 'cols' property
#=item * cols
#
#The number of columns the output should be formatted for. Text will be wrapped
#around in order to stay within this column boundry.
#The default is C<0> (zero), which is no defined column width.
#
sub GetLongUsage (@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my %args    = @_;
    my %format          = @{$args{'format'}} if exists $args{'format'};

    # Setup the description map
    # my %descriptions    = @{$args{'descriptions'}} if exists $args{'descriptions'};
    # We have to do it this alternate way, otherwise perl will throw an error if
    # any key is undef. We do not care if the value is undef.
    my %descriptions;
    if (exists $args{'descriptions'}) {
        my @temp_desc = @{$args{'descriptions'}}; # make a copy
        while (@temp_desc) {
            my $k = shift @temp_desc;
            my $v = shift @temp_desc;
            next if ! defined $k || $k eq "";
            $descriptions{$k} = $v;
        }
    }
    #DEBUG# print Dumper {"descriptions", \%descriptions};

    # Some private methods
    # &$elementexists()
    # return true if a value (element) exists in a given array ref
    my $elementexists = sub {
        my $element = shift;
        my $array = shift;
        foreach my $a (@$array) {
            return 1 if lc $element eq lc $a;
        }
        return 0;
    };
    # &$gethashvalue()
    # return the value of a given key in a hash ref, case insensitive
    my $gethashvalue = sub {
        my $key = shift;
        my $hash = shift;
        return $hash->{$key} if exists $hash->{$key};
        foreach my $hk (keys %$hash) {
            if (lc $key eq lc $hk) {
                return $hash->{$hk};
            }
        }
        return undef;
    };
    # End private methods

    # These are defined constants inside Getopt::Long, as of version 2.38
    # If these constants change inside Getopt::Long, this module will break.
    my %m = (   CTL_TYPE    => $Getopt::Long::CTL_TYPE       || 0,
                CTL_CNAME   => $Getopt::Long::CTL_CNAME      || 1,
                CTL_DEFAULT => $Getopt::Long::CTL_DEFAULT    || 2,
                CTL_DEST    => $Getopt::Long::CTL_DEST       || 3,
                CTL_DEST_SCALAR => $Getopt::Long::CTL_DEST_SCALAR    || 0,
                CTL_DEST_ARRAY  => $Getopt::Long::CTL_DEST_ARRAY     || 1,
                CTL_DEST_HASH   => $Getopt::Long::CTL_DEST_HASH      || 2,
                CTL_DEST_CODE   => $Getopt::Long::CTL_DEST_CODE      || 3,
                CTL_AMIN    => $Getopt::Long::CTL_AMIN       || 4,
                CTL_AMAX    => $Getopt::Long::CTL_AMAX       || 5
            );

    # Retrieve the Getopt::Long config map resulting from parsing the options
    if (! exists $args{'Getopt_Long'}) { warn "GetLongUsage(): Argument Getopt_Long is required."; return undef; }
    my $optionmap = ParseGetoptLongConfig(@{$args{'Getopt_Long'}});
    #DEBUG# print Dumper {"optionmap", $optionmap};

    # Create the map for the user preferred order of displaying the options.
    my $ordermap = {};  # This is the map
    my $orderindex = 0; # we'll use this one later, keeping the last value, when populating '@output'
    my $tmp_ordernumber = 0;
    if ((exists $args{'descriptions'}) && (ref($args{'descriptions'}) eq "ARRAY")) {
    while ($tmp_ordernumber < scalar @{$args{'descriptions'}}) {
        if ($elementexists->($args{'descriptions'}->[$tmp_ordernumber],$args{'hidden_opts'})) {
            $tmp_ordernumber += 2;
            next;
        }
        if (!exists $optionmap->{ lc $args{'descriptions'}->[$tmp_ordernumber] }) {
            carp ("Item \"".$args{'descriptions'}->[$tmp_ordernumber]."\" in descriptions argument is not defined as an option in Getopt_Long argument.");
        } else {
            unless ((! defined $args{'descriptions'}->[$tmp_ordernumber]) || ($args{'descriptions'}->[$tmp_ordernumber] eq "")) {
                $ordermap->{ $optionmap->{ lc $args{'descriptions'}->[$tmp_ordernumber] }[$m{'CTL_CNAME'}] } = $orderindex;
            }
            $orderindex++;
        }
        $tmp_ordernumber += 2;
    }
    #DEBUG# print Dumper {"ordermap", $ordermap};
    }

    # Create the usage message map for the options;
    my $usagemap = {};  # This is the map
    foreach my $opt (keys %$optionmap) {
        next if !defined $opt || $opt eq "";
        my $ctlname = $optionmap->{$opt}[$m{CTL_CNAME}];
        next if !defined $ctlname;
        unless (exists $usagemap->{ $ctlname }) {
            $usagemap->{ $ctlname } = [[],[]]; # [[alias1,alias2],[descline1,descline2]]
        }
        unless (lc $opt eq lc $ctlname) {
            push (@{$usagemap->{ $ctlname }[0]},$opt)
        }
        if ((@{$usagemap->{ $ctlname }[1]} == 0) && (my $desc = $gethashvalue->($opt,\%descriptions))) {
            my @lines = split("\n", $desc);
            $usagemap->{ $ctlname }[1] = \@lines;
        }
    }
    #DEBUG# print Dumper {"usagemap",$usagemap};

    # Format the text usage message for the options
    # Getopt::Long defines 'longprefix = "(--)"' in ConfigDefaults() as the
    # variable $Getopt::Long::longprefix, but does not define any "shortprefix"
    # At this time, instead of trying to figure this out, we will just use the
    # default assumed short and long prefixes.
    # It can be changed later if I get a request to do so, with suggestions on
    # how it can be accomplished.
    # For now, I will allow it as a formatting option.
    my $longprefix  = defined $format{'longprefix'} ? $format{'longprefix'} : "--";
    my $shortprefix = defined $format{'shortprefix'} ? $format{'shortprefix'} : "-";
    my $cols        = defined $format{'cols'} ? $format{'cols'} : 0;
    my $tab         = defined $format{'tab'} ? $format{'tab'} : 2;
    my $indent      = defined $format{'indent'} ? $format{'indent'} : 0;
    # Short options are assumed to be those which are only a single character
    # I do not see how options are specially identified as short in Getopt::Long
    # as it appears that both '--h' and '-h' are acceptable input
    # Short options go first, then the main long option, then aliases
    my @output; # ([[opt column],[desc column]], [[],[]], etc...);
    my $maxoptwidth = 0;
    foreach my $optname (keys %$usagemap) {
        my (@shortopt, $mainopt, @aliasopt);
        unless ($elementexists->($optname,$args{'hidden_opts'})) {
            if (length($optname) == 1) {
                push (@shortopt, ($shortprefix . $optname));
            } else {
                $mainopt = ($longprefix . $optname);
            }
        }
        foreach my $opt (@{$usagemap->{$optname}[0]}) {
            next unless defined $opt;
            next if lc $opt eq lc $optname;
            if (length($opt) == 1) {
                push (@shortopt, ($shortprefix . $opt)) unless $elementexists->($opt,$args{'hidden_opts'});
                next;
            }
            push(@aliasopt,($longprefix . $opt)) unless $elementexists->($opt,$args{'hidden_opts'});
        }
        next if @shortopt == 0 && !defined $mainopt && @aliasopt == 0;
        my @opttext;
        push (@opttext, @shortopt) if @shortopt > 0;
        push (@opttext, $mainopt) if defined $mainopt;
        push (@opttext, @aliasopt) if @aliasopt > 0;
        my $opttext = join(', ',@opttext);
        $maxoptwidth = length($opttext) if length($opttext) > $maxoptwidth;
        #push (@output, [ [$opttext], $usagemap->{$optname}[1] ] );
        my $tmp_ordernumber;
        if (exists $ordermap->{ $optname }) {
            $tmp_ordernumber = $ordermap->{ $optname };
        } else {
            $tmp_ordernumber = $orderindex;
            $orderindex++;
        }
        $output[$tmp_ordernumber] = [ [$opttext], $usagemap->{$optname}[1] ];
    }
    #DEBUG# print Dumper ("output",@output);

    # Assemble the usage text message
    my @usage;
    push (@usage, split("/$/",$args{'header'})) if defined $args{'header'};
    push (@usage, split("/$/",$args{'cli_use'})) if defined $args{'cli_use'};
    my $opttext;
    foreach my $outline (@output) {
        $opttext .= " "x$tab;
        if ((! defined $outline) || (ref $outline !~ /ARRAY/) || (! defined $outline->[0][0])) {
            $opttext .= " "x$maxoptwidth;
            $opttext .= " "x$tab;
        } else {
            $opttext .= $outline->[0][0];
            $opttext .= " "x($maxoptwidth - length($outline->[0][0]));
            $opttext .= " "x$tab;
            $opttext .= join(("\n"." "x($tab + $maxoptwidth + $tab)),@{$outline->[1]});
        }
        $opttext .= "\n";
    }
    chomp ($opttext);
    push (@usage, $opttext);
    push (@usage, split("/$/",$args{'footer'})) if defined $args{'footer'};
    my $usage;
    foreach my $line (@usage) {
        $usage .= " "x$indent;
        $line =~ s/\n/("\n"." "x$indent)/eg;
        $usage .= $line;
        $usage .= "\n";
    }

    # Return the usage text message to the caller
    return $usage;
}


1;
__END__

=pod

=head1 NAME

Getopt::LongUsage - Describe the usage of Getopt::Long options in human readable format

=head1 SYNOPSIS

Provide the description for Getopt::Long options in order to generate a
descriptive usage for the user.

Example code:

    use Getopt::Long;
    use Getopt::LongUsage;

    my ($width,$length,$verbose,$help);
    my @getoptconf = (  'width=i'   => \$width,
                        'length=i'  => \$length,
                        'verbose|v' => \$verbose,
                        'help|h'    => \$help
                        );
    my $usage = sub {
        my @getopt_long_configuration = @_;
        GetLongUsage (
            'cli_use'       => ($0 ." [options]"),
            'descriptions'  =>
                [   'width'         => "The width",
                    'length'        => "The length",
                    'verbose'       => "verbose",
                    'help'          => "this help message"
                    ],
            'Getopt_Long'   => \@getopt_long_configuration,
        );
    };
    GetOptions( @getoptconf ) || die ($usage->( @getoptconf ),"\n");
    ...etc...

Example output:

    linux$ ./test_it.pl --not-an-option
    Unknown option: not-an-option
    ./test_it.pl [options]
      --width        The width
      --length       The length
      -v, --verbose  verbose
      -h, --help     this help message

=head1 DESCRIPTION

This is a pure perl module which generates a user help message for a perl script
that implements the C<Getopt::Long> module. Simply describe each option
configured for C<Getopt::Long>, and a useful formatted help message is
generated.

=head1 REQUIREMENTS

The following perl modules are depended on by this module:

=over 4

=item *     Getopt::Long

=back

=head1 IMPORTED METHODS

When the calling application invokes this module in a use clause, the following
method will be imported into its space.

=over 4

=item *     C<GetLongUsage>

=back

=head1 METHODS


=head2 new

Create a new object instances of this module.
It is not necessary to create an object for this module, as the methods can
be called outside of OO style programming.

=over 4

=item * I<returns>

An object instance of this module.

=back

    my $glu = new Getopt::LongUsage();


=head2 ParseGetoptLongConfig

Parse option configuration for C<Getopt::Long>.
This is also known as the "Spec parser" for <Getopt::Long>.

This method reproduces just enough code as found in
C<Getopt::Long::GetOptionsFromArray()>, while also calling functions in that
module, so to parse the same exact C<Getopt::Long> configuration input.

Unlike other <Getopt::Long> "Spec parsers", this function parses the argument
configuration in the exact same procedure as <Getopt::Long>.

    my $configmap = ParseGetoptLongConfig (
                        \%options,
                        'isAvailable',
                        'color=s',
                        'type=s',
                        'cityGrown=s@',
                        'secretAttr=i',
                        'verbose|v',
                        'help|h'
                    );

or

    my @getoptconf = (
                      	'isAvailable'  => \$isAvailable,
                        'color=s'      => \$color,
                        'type=s'       => \$type,
                        'cityGrown=s@' => \@cityGrown,
                        'secretAttr:i' => \$secretAttr,
                        'verbose|v'    => \$verbose,
                        'help|h'       => \$help
                        );
    my $configmap = ParseGetoptLongConfig ( @getoptconf );

=head3 Resulting Config Map documentation, extracted from Getopt::Long

The C<Getopt::Long::ParseGetoptLongConfig> is a function utilizing code copied
right out of C<Getopt::Long> to ensure complete compatibility. The author of
this C<Getopt::LongUsage> module has communicated with the author of the
C<Getopt::Long> module about this action.

The following documentation is assembled based on definitions and code
found inside the C<Getopt::Long> source code.

A look at the resulting output from C<Getopt::LongUsage::ParseGetoptLongConfig>

Perl Code

    use Getopt::Long;
    use Getopt::LongUsage;
    use Data::Dumper;
    my $configmap = Getopt::LongUsage::ParseGetoptLongConfig (
                        \%options,
                        'inti_opt=i',
                        'stri_opt:s',
                        'flag_opt|f'
                    );
    print Dumper ( $configmap );

Output

    $VAR1 = {
          'inti_opt' => [
                          'i',
                          'inti_opt',
                          undef,
                          0,
                          1,
                          1
                        ],
          'flag_opt' => [
                          '',
                          'flag_opt',
                          undef,
                          0,
                          0,
                          0
                        ],
          'stri_opt' => [
                          's',
                          'stri_opt',
                          undef,
                          0,
                          0,
                          1
                        ],
          'f' => $VAR1->{'flag_opt'}
        };

Description and definition from C<Getopt::Long>, in short form

          # Hash_Key => [Config_Vals] # Array_Index - NAME :possible values (or) -definition
          'stri_opt' => [
                          's',        # 0 - CTL_TYPE    : ''=FLAG,!=NEG,+=INCR,i=INT,I=INTINC,o=XINT,f=FLOAT,s=STRING
                          'stri_opt', # 1 - CTL_CNAME   - The name of the option
                          undef,      # 2 - CTL_DEFAULT - The default value of the option
                          0,          # 3 - CTL_DEST    : 0=SCALAR, 1=ARRAY, 2=HASH, 3=CODE
                          1,          # 4 - CTL_AMIN    - Minimum expected values
                          1           # 5 - CTL_AMAX    - Maximum allowed values (-1 == unlimited)
                        ],


=head2 GetLongUsage

Generate a usage message from Getopt::Long options.

=over 4

=item * B<header>

This is a text string to be used as a header of the usage output. It will appear
at the top of the usage output.

=item * B<footer>

This is a text string to be used as a footer of the usage output. It will appear
at the bottom of the usage output.

=item * B<cli_use>

This is a string representing the format for executing your application.

=item * B<descriptions>

This is an array reference of options with descriptions. The order of the
options provided to the C<descriptions> parameter dictates the presentation
order. The format is as follows:

    my $descriptions = [ 'opt1' => 'desc1', 'opt2' => 'desc2', etc... ]

The options should be one that is found in the Getopt::Long configuration passed
to the C<Getopt_Long> parameter. If the configuration consists of both long and
short options, you should only provide one of them. The description is
associated with all related options as configured for Getopt::Long.

So for example, if the following is your Getopt::Long configuration:

    GetOptions( %options, 'help|h', 'opt1|o')

Then the following two C<descriptions> configurations would be valid:

    $descriptions = [   'h' => "This help message",
                        'o' => "The first option"   ]

    $descriptions = [   'help' => "This help message",
                        'opt1' => "The first option"   ]

It does not matter if you use either the long or short form of the options, as
it is only used in this parameter for the purpose of associating the given
description with a relation of options in the Getopt::Long configuration.

=item * B<format>

Formatting options are set in subparameters within this parameter.

=over 4

=item * tab

The number of spaces that comprise a tab in the formatted output.
The default is C<2> spaces for each tab.

=item * indent

The number of spaces to indent the formatted output.
The default is C<0> spaces.

=item * longprefix

The prefix that defines long options. The default is C<-->, as in C<--help>.

=item * shortprefix

The prefix that defines short options. The default is C<->, as in C<-h>.

=back

=item * B<hidden_opts>

This is an array reference list of Getopt::Long options that will be hidden from
the formatted usage message intended for human reading.

=item * B<Getopt_Long>

The array reference list of a Getopt::Long configuration which is a definition
of the expected C<Getopt::Long::GetOptions()> input option.

=back

    GetLongUsage (  header          => "This is my header text",
                    footer          => "This is my footer text"
                    cli_use         => "myprog [options] arg1 arg2",
                    descriptions    => \@descriptions,
                    format          => \@format_options,
                    hidden_opts     => \@hidden_options,
                    Getopt_Long     => \@getopt_long_options
                    );


=head1 EXAMPLES

=head2 Actually, the descriptions are not needed either

Example code:

    use Getopt::Long;
    use Getopt::LongUsage;
    
    my %options;
    my @getoptconf = (  \%options,
                        'isAvailable',
                        'color=s',
                        'type=s',
                        'cityGrown=s@',
                        'verbose|v',
                        'help|h'
                        );
    my $usage = sub {
        my @getopt_long_configuration = @_;
        GetLongUsage (
            'Getopt_Long'   => \@getopt_long_configuration,
        );
    };
    GetOptions( @getoptconf ) || die ($usage->( @getoptconf ),"\n");
    ...etc...

Example output:

    linux$ perl test.pl --notanoption
    Unknown option: notanoption
      -v, --verbose  
      --isAvailable  
      --color        
      -h, --help     
      --type         
      --cityGrown

=head2 Using more formatting options

Example code:

    use Getopt::Long;
    use Getopt::LongUsage;
    
    my $VERSION = "2.1.5";
    my %options;
    my @getoptconf = (  \%options,
                        'isAvailable',
                        'color=s',
                        'type=s',
                        'cityGrown=s@',
                        'secretAttr:i',
                        'verbose|v',
                        'help|h'
                        );
    my $usage = sub {
        my @getopt_long_configuration = @_;
        GetLongUsage (
            'header'        => ("MyApple Program version ".$VERSION."\n".'Author Smith <author@example.com>'."\n"),
            'cli_use'       => ($0 ."[options] <args>"),
            'descriptions'  =>
                [   'isAvailable'   => "The apple type is available",
                    'color'         => "The color of this apple type",
                    'type'          => "The type of apple, i.e. \"Gala\"",
                    'cityGrown'     => "The city(s) in which this apple is grown",
                    'secretAttr'    => "You should not see this option",
                    'verbose'       => "verbose",
                    'help'          => "help"
                    ],
            'hidden_opts    => [qw(secretAttr)]
            'footer'        => undef,
            'format'        =>
                [   'tab'       => 4,
                    'indent'    => 0
                    ],
            'Getopt_Long'   => \@getopt_long_configuration,
        );
    };
    GetOptions( @getoptconf ) || die ($usage->( @getoptconf ),"\n");
    ...etc...

Example output:

    MyApple Program version 2.1.5
    Author Smith <author@example.com>
    
    script.pl [options] <args>
        --isAvailable    The apple type is available
        --color          The color of this apple type
        --type           The type of apple, i.e. "Gala"
        --cityGrown      The city(s) in which this apple is grown
        -v, --verbose    verbose
        -h, --help       help

=head2 Combining Getopt::XML with Getopt::LongUsage

Considering the following XML File '/path/to/xml_file.xml' and content:

    <apple>
        <color>red</color>
        <type>red delicious</type>
        <isAvailable/>
        <cityGrown>Macomb</cityGrown>
        <cityGrown>Peoria</cityGrown>
        <cityGrown>Galesburg</cityGrown>
    </apple>

Using that XML file as input for default values:

    use Getopt::Long;
    use Getopt::LongUsage;
    use Getopt::XML qw(GetXMLOptionsFromFile);
    use Data::Dump qw(pp);
    #
    # Set the Getopt::Long Configuration
    my @GetoptLongConfig = (
                                \%options,
                                'isAvailable',
                                'color=s',
                                'type=s',
                                'cityGrown=s@'
                            );
    #
    # Read the XML data in as arguments to Getopt::Long
    my %options;
    GetXMLOptionsFromFile (
            xmlfile     => '/path/to/xml_file.xml',
            xmlpath     => '/apple',
            Getopt_Long => \@GetoptLongConfig
    );
    print "==My Default Values==\n";
    pp(\%options);
    #
    # Setup the user's help message for Getopt::Long
    my $usage = sub {
        my @getopt_long_configuration = @_;
        GetLongUsage (
            'header'        => ("MyApple Program version ".$VERSION."\n".'Author Smith <author@example.com>'."\n"),
            'cli_use'       => ($0 ." [options] <args>"),
            'descriptions'  =>
                [   'isAvailable'   => "The apple type is available",
                    'color'         => "The color of this apple type",
                    'type'          => "The type of apple, i.e. \"Gala\"",
                    'cityGrown'     => "The city(s) in which this apple is grown"
                    ],
            'footer'        => "\n",
            'format'        =>
                [   'tab'       => 2,
                    'indent'    => 2
                    ],
            'Getopt_Long'   => \@getopt_long_configuration,
        );
    };
    #
    # Finally retrieve and absorb the user provided input via Getopt::Long
    GetOptions( @GetoptLongConfig ) || die ($usage->( @GetoptLongConfig ));
    print "==My Runtime Values==\n";
    pp(\%options);

Example output when providing an invalid option

    linux$ perl test.pl --notanoption
    ==My Default Values==
    {
      cityGrown => ["Macomb", "Peoria", "Galesburg"],
      color => "red",
      isAvailable => 1,
      type => "red delicious",
    }
    Unknown option: notanoption
      MyApple Program version 
      Author Smith <author@example.com>
      
      test.pl [options] <args>
        --isAvailable  The apple type is available
        --color        The color of this apple type
        --type         The type of apple, i.e. "Gala"
        --cityGrown    The city(s) in which this apple is grown

Example output when providing a valid option

    linux$ perl test.pl --color="blue" --type="blue delicious"
    ==My Default Values==
    {
      cityGrown => ["Macomb", "Peoria", "Galesburg"],
      color => "red",
      isAvailable => 1,
      type => "red delicious",
    }
    ==My Runtime Values==
    {
      cityGrown => ["Macomb", "Peoria", "Galesburg"],
      color => "blue",
      isAvailable => 1,
      type => "blue delicious",
    }

=head1 TODO

=over 4

=item 1 Support the definition of the column width in the usage message output

By defining a C<format> subparameter called C<cols> in C<GetLongUsage()>, one
can define how wide (how many columns) the usage message output should be
constrained within. In conforming to a maximum column size, the options
sub-column and option description sub-column will be adjusted to fit that width
in the following ways:

1. The options sub-column may be formatted such that particularly long rows of
this sub-column will be on a line of its own, and its associated description
will begin on the next line - though in the description sub-column

2. The option description sub-column may be formatted such that descriptions
which span beyond the sub-column width will be wrapped to the next line.

    --thisisaverylongoption
                        The descriotion has to start on the next line because the
                        option is too long. Also this description wraps around
                        because it is also too long.
    -a, --another, --param2
                        This is also true for options like this one.
    -h, --help, -?      This option and description fits.

=item 1 Display the input type for each option in the usage message output

Currently the usage message only displays the options and relation option
aliases for each option. The required input format is not provided. So by only
looking at the options in the usage message output, a user does not know if
the option is a boolean flag, requires a string text as input, or requires a
number as input.

The C<ParseGetopLongConfig()> method already returns a map of the option
configuration which describes the expected input (as boolean flag, string, or
integer). The C<GetLongUsage()> method need only utilize that available data
when formatting the usage message.

A flag may be provided to allow the caller to turn this off or on, and maybe
even possibly format what it looks like. I am considering something like
the following as default, which just mimics the Getopt::Long configuration
style:

    --booleanflag
    --number=i
    --yourname=s

=item 1 Support for optionally displaying aliases on their own line

Currently the aliases and their main parameters are displayed on the same line.
However, it may be desired to have them on a separated line, and reference
the main parameter.

So instead of:

    -h, -?, --help        This help message
    -v, --verbose, --ver  Turn on verbose messaging

It would be:

    -h, -?, --help  This help message
    -v, --verbose   Turn on verbose messaging
    --ver           Alias for --verbose

=back

=head1 AUTHOR

Russell E Glaue, http://russ.glaue.org

=head1 SEE ALSO

C<Getopt::Long>

C<Getopt::XML>

Getopt::LongUsage on Codepin: http://www.codepin.org/project/perlmod/Getopt-LongUsage

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2013 Russell E Glaue,
Center for the Application of Information Technologies,
Western	Illinois University.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
