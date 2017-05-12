package ExtUtils::ModuleMaker::Interactive;
#$Id$
use strict;
use warnings;
BEGIN {
    use base qw( ExtUtils::ModuleMaker );
    use vars qw ( $VERSION ); 
    $VERSION = 0.56;
}
use Carp;
use Data::Dumper;

########## CONSTRUCTOR ##########
#
# Inherited from EU::MM
#
########## BEGIN DECLARATIONS ##########

###### Index of Variables (08/18/2005):

# %Build_Menu
# %destinations
# %Directives_Menu
# %Flagged
# $License_Standard
# $License_Local
# @lic
# %messages

my %Build_Menu = (
    E => 'ExtUtils::MakeMaker',
    B => 'Module::Build',
    P => 'Module::Build and proxy Makefile.PL',
);

my %destinations = (
    'Main Menu' => {
        A => 'Author Menu',
        L => 'License Menu',
        D => 'Directives_Menu',
        B => 'Build Menu',
        X => 'exit',
    },
    'Author Menu' => {
        R => 'Main Menu',
        X => 'exit',
    },
    Directives_Menu => {
        R => 'Main Menu',
        X => 'exit',
    },
    'License Menu' => {
        C => 'Copyright_Display',
        L => 'License_Display',
        P => 'License Menu',
        R => 'Main Menu',
        X => 'exit',
    },
    'Build Menu' => {
        R => 'Main Menu',
        X => 'exit',
    },
);

my %Flagged = (
    ( map { $_ => 0 } qw (0 N F) ),
    ( map { $_ => 1 } qw (1 Y T) ),
);

my $License_Standard = ExtUtils::ModuleMaker::Licenses::Standard->interact();
my $License_Local    = ExtUtils::ModuleMaker::Licenses::Local->interact();
my @lic              = (
    (
        map { [ $_, $License_Standard->{$_} ] }
          sort { $License_Standard->{$a} cmp $License_Standard->{$b} }
          keys( %{$License_Standard} )
    ),
    (
        map { [ $_, $License_Local->{$_} ] }
          sort { $License_Local->{$a} cmp $License_Local->{$b} }
          keys( %{$License_Local} )
    ),
);

my %messages = (
    #---------------------------------------------------------------------

    'Main Menu' => <<EOF,
modulemaker: Main Menu

    Feature                     Current Value
N - Name of module              '##name##'
S - Abstract                    '##abstract##'
A - Author information
L - License                     '##license##'
D - Directives
B - Build system                '##build##'

G - Generate module
H - Generate module;
    save selections as defaults

X - Exit immediately

Please choose which feature you would like to edit: 
EOF
    #---------------------------------------------------------------------

    'Author Menu' => <<EOF,
modulemaker: Author Menu

    Feature       Current Value
##Data Here##

R - Return to main menu
X - Exit immediately

Please choose which feature you would like to edit:
EOF

    #---------------------------------------------------------------------

    Directives_Menu => <<EOF,
modulemaker: Directives Menu

    Feature           Current Value
##Data Here##

R - Return to main menu
X - Exit immediately

Please choose which feature you would like to edit:
EOF

    #---------------------------------------------------------------------

    'License Menu' => <<EOF,
modulemaker: License Menu

ModuleMaker provides many licenes to choose from, many of them approved by opensource.org.

        License Name
##Licenses Here##

# - Enter the number of the license you want to use
C - Display the Copyright
L - Display the License
R - Return to main menu
X - Exit immediately

Please choose which license you would like to use:
EOF

    #---------------------------------------------------------------------

    License_Display => <<EOF,
Here is the current license:

##License Here##

C - Display the Copyright
L - Display the License
P - Pick a different license
R - Return to main menu
X - Exit immediately

Please choose which license you would like to use:
EOF

    #---------------------------------------------------------------------

    Copyright_Display => <<EOF,
Here is the current copyright:

##Copyright Here##

C - Display the Copyright
L - Display the License
P - Pick a different license
R - Return to main menu
X - Exit immediately

Please choose which license you would like to use:
EOF

    #---------------------------------------------------------------------

    Build_Menu => <<EOF,
Here is the current build system:

##Build Here##

E - ExtUtils::MakeMaker
B - Module::Build
P - Module::Build and proxy Makefile.PL
R - Return to main menu
X - Exit immediately

Please choose which build system you would like to use:
EOF

    #---------------------------------------------------------------------
);

########## END DECLARATIONS ##########

########## BEGIN PUBLIC METHODS ##########  

##### Index of Methods (08/18/2005) #####

##### Public #####

# run_interactive
# closing_message

##### Private #####

# _prepare_author_defaults
# Main_Menu
# Author_Menu
# Directives_Menu
# License_Menu
# License_Display
# Build_Menu
# Copyright_Display
# Question_User

sub run_interactive {
    my $MOD = shift;
    my $where = 'Main Menu';
    while () {
        if ( $where eq 'exit' ) {
            print "Exiting immediately!\n\n";
        exit 0;
        } elsif ( $where eq 'done' ) {
            last;
        } elsif ( $where eq 'Module Name' ) {
        } elsif ( $where eq 'Abstract' ) {
        } elsif ( $where eq 'Main Menu' ) {
            $where = Main_Menu($MOD);
        } elsif ( $where eq 'License Menu' ) {
            $where = License_Menu($MOD);
        } elsif ( $where eq 'Author Menu' ) {
            $where = Author_Menu($MOD);
        } elsif ( $where eq 'License_Display' ) {
            $where = License_Display($MOD);
        } elsif ( $where eq 'Copyright_Display' ) {
            $where = Copyright_Display($MOD);
        } elsif ( $where eq 'Directives_Menu' ) {
            $where = Directives_Menu($MOD);
        } elsif ( $where eq 'Build Menu' ) {
            $where = Build_Menu($MOD);
        } else {
            $where = Main_Menu($MOD);
        }
    }
    return $MOD;
}

sub closing_message {
    my $MOD = shift;
    print "\n-------------------\n\nModule files generated.  Good bye.\n\n";
}

########## END PUBLIC METHODS ##########

########## BEGIN PRIVATE METHODS ##########

sub _prepare_author_defaults {
    my $self = shift;
    my $defaults_ref = $self->default_values();
    my %author_defaults = (
        AUTHOR  => {
                default  => $defaults_ref->{AUTHOR},
                string   => 'Author      ',
                opt      => 'u',
                select   => 'N',
            },
        CPANID => {
                default  => $defaults_ref->{CPANID},
                string   => 'CPAN ID     ',
                opt      => 'p',
                select   => 'C',
            },
        ORGANIZATION => {
                default  => $defaults_ref->{ORGANIZATION},
                string   => 'Organization',
                opt      => 'o',
                select   => 'O',
            },
        WEBSITE => {
                default  => $defaults_ref->{WEBSITE},
                string   => 'Website     ',
                opt      => 'w',
                select   => 'W',
            },
        EMAIL => {
                default  => $defaults_ref->{EMAIL},
                string   => 'Email       ',
                opt      => 'e',
                select   => 'E',
            },
    );
    return { %author_defaults };
}

sub _prepare_directives_defaults {
    my $self = shift;
    my $defaults_ref = $self->default_values();
    my %directives_defaults = (
        COMPACT  => {
                default  => $defaults_ref->{COMPACT},
                string   => 'Compact        ',
                opt      => 'c',
                select   => 'C',
            },
        VERBOSE  => {
                default  => $defaults_ref->{VERBOSE},
                string   => 'Verbose        ',
                opt      => 'V',
                select   => 'V',
            },
        NEED_POD  => {
                default  => $defaults_ref->{NEED_POD},
                string   => 'Include POD    ',
                opt      => 'P',
                select   => 'D',
            },
        NEED_NEW_METHOD  => {
                default  => $defaults_ref->{NEED_NEW_METHOD},
                string   => 'Include new    ',
                opt      => 'q',
                select   => 'N',
            },
        CHANGES_IN_POD  => {
                default  => $defaults_ref->{CHANGES_IN_POD},
                string   => 'History in POD ',
                opt      => 'C',
                select   => 'H',
            },
        PERMISSIONS  => {
                default  => $defaults_ref->{PERMISSIONS},
                string   => 'Permissions    ',
                opt      => 'r',
                select   => 'P',
            },
    );
    return { %directives_defaults };
}

sub Main_Menu {
    my $MOD = shift;

    MAIN_LOOP:  {
        my $string = $messages{'Main Menu'};
        defined $MOD->{NAME} 
            ? $string =~ s|##name##|$MOD->{NAME}|
            : $string =~ s|##name##||;
        $string =~ s|##abstract##|$MOD->{ABSTRACT}|;
        $string =~ s|##license##|$MOD->{LICENSE}|;
        $string =~ s|##build##|$MOD->{BUILD_SYSTEM}|;
    
        my $response = Question_User( $string, 'menu' );
    
        return ( $destinations{'Main Menu'}{$response} )
          if ( exists $destinations{'Main Menu'}{$response} );
    
        if ( $response eq 'N' ) {
            my $value =
              Question_User( "Please enter a new value for Primary Module Name",
                'data' );
            $MOD->{NAME} = $value;
        }
        elsif ( $response eq 'S' ) {
            my $value =
              Question_User( "Please enter Abstract (suggest: 44-char max)",
                'data' );
            $MOD->{ABSTRACT} = $value;
        }
        elsif ( $response eq 'G' or $response eq 'H' ) {
            $MOD->set_author_composite();
            if (! $MOD->{NAME}) {
                print "ERROR:  Must enter module name!\n";
                next MAIN_LOOP;
            } elsif ($MOD->validate_values()) {
                $MOD->set_file_composite();
                if ( $response eq 'G' ) {
                    print "Module files are being generated.\n";
                } else {
                    $MOD->make_selections_defaults();
                    print "Module files are being generated;\n";
                    print "  selections are being saved as defaults.\n";
                }
                return ('done');
            } else {
                next MAIN_LOOP;
            }
        }
    } # END MAIN_LOOP
    return ('Main Menu');
}

sub Author_Menu {
    my $MOD = shift;

    my $author_defaults_ref = $MOD->_prepare_author_defaults();
    my %author_defaults = %{$author_defaults_ref};
    my %Author_Menu = map {
        $author_defaults{$_}{select} => 
            [ $author_defaults{$_}{string}, $_ ]
        } keys %author_defaults;

    my $string = $messages{'Author Menu'};
    my $stuff  = join( "\n", map {
            qq{$_ - $Author_Menu{$_}[0]  '}             #'
              . $MOD->{ $Author_Menu{$_}[1] } . q{'}
          } qw (N C O W E)
    );
    $string =~ s|##Data Here##|$stuff|;

    my $response = Question_User( $string, 'menu' );
    return ( $destinations{'Author Menu'}{$response} )
      if ( exists $destinations{'Author Menu'}{$response} );
    return ('Author Menu') unless ( exists( $Author_Menu{$response} ) );

    my $value =
      Question_User( "Please enter a new value for $Author_Menu{$response}[0]",
        'data' );
    $MOD->{ $Author_Menu{$response}[1] } = $value;

    return ('Author Menu');
}

sub Directives_Menu {
    my $MOD = shift;
# warn "at start of Directives_Menu:  $MOD->{COMPACT}\n";
    my $directives_defaults_ref = $MOD->_prepare_directives_defaults();
    my %directives_defaults = %{$directives_defaults_ref};
    my %Directives_Menu = map { 
        $directives_defaults{$_}{select} => 
            [ $directives_defaults{$_}{string}, $_ ]
    } keys %directives_defaults;

    my $string = $messages{Directives_Menu};
    my $stuff  = join( "\n",
        (
            map {
                qq{$_ - $Directives_Menu{$_}[0]  '}             #'
                  . $MOD->{ $Directives_Menu{$_}[1] } . q{'}
#                  . $Directives_Menu{$_}[1] . q{'}
              } qw (C V D N H)
        ),
        qq{P - $Directives_Menu{P}[0]  '}
          . sprintf(
            "%04o - %d",
            $MOD->{ $Directives_Menu{P}[1] },
            $MOD->{ $Directives_Menu{P}[1] }
          )
          . q{'},
    );
    $string =~ s|##Data Here##|$stuff|;

    my $response = Question_User( $string, 'menu' );
    return ( $destinations{Directives_Menu}{$response} )
      if ( exists $destinations{Directives_Menu}{$response} );
    return ('Directives_Menu') unless ( exists( $Directives_Menu{$response} ) );

    if ( $response eq 'P' ) {
        my $value =
          Question_User(
            "Please enter a new value for $Directives_Menu{$response}[0]",
            'data' );
        $value = oct($value) if ( $value =~ /^0/ );
        $MOD->{ $Directives_Menu{$response}[1] } = $value if ( $value <= 0777 );
    }
    else {
        my $value = Question_User(
            "Please enter a new value for $Directives_Menu{$response}[0]," . " (0,No,False  || 1,Yes,True)",
            'menu'
        );
        $value = $Flagged{$value};
        $MOD->{ $Directives_Menu{$response}[1] } = $Flagged{$value}
          if ( exists $Flagged{$value} );
    }

    return ('Directives_Menu');
}

sub License_Menu {
    my $MOD = shift;

    my $string   = $messages{'License Menu'};
    my $ct       = 1;
    my $licenses = join(
        "\n",
        map {
                $ct++ . ( ( $MOD->{LICENSE} eq $_->[0] ) ? '***' : '' ) . "\t"
              . $_->[1]
          } @lic
    );
    $string =~ s|##Licenses Here##|$licenses|;

    my $response = Question_User( $string, 'license', scalar(@lic) );
    return ( $destinations{'License Menu'}{$response} )
      if ( exists $destinations{'License Menu'}{$response} );

    if ( $lic[ $response - 1 ] ) {
        $MOD->{LICENSE} = $lic[ $response - 1 ][0];
    }
    $MOD->initialize_license();

    return ('License Menu');
}

sub License_Display {
    my $MOD = shift;

    my $string = $messages{License_Display};
    $string =~ s|##License Here##|$MOD->{LicenseParts}{LICENSETEXT}|;

    my $response = Question_User( $string, 'menu' );
    return ( $destinations{'License Menu'}{$response} )
      if ( exists $destinations{'License Menu'}{$response} );
    return ('License Menu');
}

sub Build_Menu {
    my $MOD = shift;

    my $string = $messages{Build_Menu};
    $string =~ s|##Build Here##|$MOD->{BUILD_SYSTEM}|;

    my $response = Question_User( $string, 'menu' );
    return ( $destinations{'Build Menu'}{$response} )
      if ( exists $destinations{'Build Menu'}{$response} );

    $MOD->{BUILD_SYSTEM} = $Build_Menu{$response}
      if exists $Build_Menu{$response};

    return ('Build Menu');
}

sub Copyright_Display {
    my $MOD = shift;

    my $string = $messages{Copyright_Display};
    $string =~ s|##Copyright Here##|$MOD->{LicenseParts}{COPYRIGHT}|;

    my $response = Question_User( $string, 'menu' );
    return ( $destinations{'License Menu'}{$response} )
      if ( exists $destinations{'License Menu'}{$response} );
    return ('License Menu');
}

sub Question_User {
    my ( $question, $flavor, $feature ) = @_;

    print "\n------------------------\n\n", $question, "\n";
    my $answer = <>;

    if ( $flavor eq 'menu' ) {
        $answer =~ m/^(.)/;
        $answer = uc($1);
    }
    elsif ( $flavor eq 'data' ) {
        chomp($answer);
    }
    elsif ( $flavor eq 'license' ) {
        chomp($answer);
        unless ( $answer =~ m/^\d+/ ) {
            $answer =~ m/^(.)/;
            $answer = uc($1);
        }
        elsif ( ( $answer < 1 ) || ( $feature < $answer ) ) {
            $answer = 'P';
        }
    }

    print "You entered '$answer'\n";
    return ($answer);
}

########## END PRIVATE METHODS ##########

1;

################### DOCUMENTATION ################### 

=head1 NAME

ExtUtils::ModuleMaker::Interactive - Hold methods used in F<modulemaker>

=head1 SYNOPSIS

    use ExtUtils::ModuleMaker::Interactive;

    $mod = ExtUtils::ModuleMaker::Interactive->new(%standard_options);

    $mod->run_interactive() if $mod->{INTERACTIVE};

    ...  # ExtUtils::ModuleMaker::complete_build() called here
    
    $mod->closing_message();

=head1 DESCRIPTION

This package exists solely to hold declarations of variables and
methods used in F<modulemaker>, the command-line utility which is
the easiest way of accessing the functionality of Perl extension
ExtUtils::ModuleMaker.

=head1 METHODS

=head2 C<run_interactive()>

This method drives the menus which make up F<modulemaker>'s interactive mode.
Once it has been run, F<modulemaker> calls
C<ExtUtils::ModuleMaker::complete_build()> to build the directories and files
requested.

=head2 C<closing_message()>

Prints a closing message after C<complete_build()> is run.  Can be commented
out without problem.  Could be subclassed, and -- in a future version --
probably will be with an optional printout of files created.

=head1 AUTHOR

James E Keenan.  CPANID:  JKEENAN.

=head1 COPYRIGHT

Copyright (c) 2005, 2017 James E. Keenan.  All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

F<modulemaker>, F<ExtUtils::ModuleMaker>.

=cut


