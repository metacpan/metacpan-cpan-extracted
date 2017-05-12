=head1 NAME

File::OSS::Scan::Ruleset - initialize the scan rules

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use File::OSS::Scan::Ruleset;

    File::OSS::Scan::Ruleset->init($config_file);
    my $ruleset = File::OSS::Scan::Ruleset->get_ruleset();

=head1 DESCRIPTION

This is an internal module used by L<File::OSS::Scan> to initialise scan rules from
the configuration file, and should not be called directly.

=head1 SEE ALSO

=over 4

=item * L<File::OSS::Scan>

=back

=head1 AUTHOR

Harry Wang <harry.wang@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Harry Wang.

This is free software, licensed under:

    Artistic License 1.0

=cut

package File::OSS::Scan::Ruleset;

use strict;
use warnings FATAL => 'all';

use Fatal qw( open close );
use Carp;
use English qw( -no_match_vars );
use Data::Dumper; # for debug

use File::OSS::Scan::Constant qw(:all);

our $VERSION = '0.04';

my $cfg_default = $ENV{OSSSCAN_CONFIG} || ".ossscan.rc";
my @valid_sections = qw/GLOBAL FILE DIRECTORY LINE/;

# global var ...
our $ruleset = undef;

sub init {
    my $self = shift;
    my $config_file = shift || $cfg_default;

    local *CONFIG;

    if ( ! -f $config_file ) {
        carp "config file $config_file doesn't exist, using the embedded ruleset.";

        # read from __DATA__ section
        *CONFIG = *DATA;
    }
    else {
        croak "config file $config_file is not readable."
            if ( ! -r $config_file );

        open( CONFIG, $config_file ) ||
            croak "Can't open $config_file, $!.";
    }

    # clear previously set config $ruleset
    undef $ruleset;

    my ( $section, $rule ) = ( undef, undef );
    my $invalid_section_flag = UNI_FALSE;

    while(<CONFIG>) {
        chomp;      # remove newline
        s/#.*//;    # remove comments
        s/^\s+//;   # remove leading spaces
        s/\s+$//;   # remove trailing spaces

        # anything left ?
        next unless length;

        # parse sections
        if ( /^\[(\w+)\].*/ ) {
            $section = uc $1;

            # skip invalid sections
            if (  ! grep {/^$section$/} @valid_sections ) {
                carp "Invalid section name $section, skipping ...";
                $invalid_section_flag = UNI_TRUE;
                next;
            } else {
                $invalid_section_flag = UNI_FALSE;
            }

            $ruleset->{$section} = undef
                if ( not exists $ruleset->{$section} );
        }

        # parse settings
        # put them all under 'GLOBAL' section
        if ( /^(\w+)\s*\:\s*(.*)$/ ) {
            my ( $key, $val ) = ( $1, $2 );
            $ruleset->{'GLOBAL'}->{$key} = [ split /\s+/, $val ];
        }

        # parse rules
        # if ( /^([\w\%\-\s]+)$/ ) {
        if ( /^(\d+\%?.*)$/ ) {
            $rule = $1;

            # skip rules under invalid sections
            if ( $invalid_section_flag ) {
                carp "also skipping rules $rule under invalid section $section ...";
                next;
            }

            my $cur_section = $section || 'GLOBAL';

            my ( $certain, $func, @args )
                = split(' ', $rule);

            # valid level of certainty: 0 - 100
            if ( $certain =~ /^(\d+)\%?$/ ) {
                $certain = $1;

                if ( $certain > 100 or $certain < 0 ) {
                    carp "certainty $certain is not in the range of 0 to 100, skipping rules $rule ...";
                    next;
                }
            }
            else {
                carp "invalid level of certainty $certain, skipping rules $rule ...";
                next;
            }

            my $hash = {
                'cert'  => $certain,
                'func'  => $func,
                'args'  => \@args
            };

            push @{$ruleset->{$cur_section}}, $hash;
        }

    }

    close( CONFIG );

    # sort rulesets by certainty level
    sort_ruleset();

    return SUCCESS;
}

sub get_ruleset {
    my $var = $_[0] . "::ruleset";
    no strict 'refs';
    return $$var;
}

sub sort_ruleset {

    # sort every sections of ruleset according to
    # its level of certainty.
    foreach my $sec ( @valid_sections ) {

        # don't sort global setting
        next
            if ( $sec eq 'GLOBAL' );

        if ( exists $ruleset->{$sec} and
                defined $ruleset->{$sec} ) {

            my @sorted = ();
            my %raw_hash = ();
            my $rules = $ruleset->{$sec};

            foreach my $rule ( @$rules ) {
                my $cert = $rule->{'cert'};
                push @{$raw_hash{$cert}}, $rule;
            }

            foreach my $s_cert ( sort { $b <=> $a } keys %raw_hash ) {
                push @sorted, @{$raw_hash{$s_cert}};
            }

            $ruleset->{$sec} = \@sorted;
        }
    }

    return SUCCESS;
}


1;



__DATA__

exclude_extension: png jpg gif pdf doc docx html htm xml json xls

# section for directory check
[DIRECTORY]

# section for file check
[FILE]
    100% filename_match COPYING
    100% filename_match COPYING\.\w+
    100% filename_match LICEN[CS]E
    100% filename_match LICEN[CS]E\.\w+
    100% filename_match KEY[S]?
    100% filename_match KEY[S]?.\w+
    50%  filename_match AUTHOR[S]?

# section for line check
[LINE]
    100% content_match GPL 1
    100% content_match GPLv\d 1
    100% content_match LGPL 1
    100% content_match LGPLv\d 1
    100% content_match BSD.*Licen[cs]e
    100% content_match Public\W*Licen[cs]e
    100% content_match Public\W*WAttribution
    100% content_match Open\W*Licen[cs]e
    100% content_match Open\W*Source\W*Licen[cs]e
    100% content_match Software\W*Licen[cs]e
    100% content_match Library\W*Licen[cs]e
    100% content_match Free\W*Licen[cs]e
    100% content_match MIT\W*Licen[cs]e
    100% content_match Sleepycat\W*Licen[cs]e
    100% content_match Apache.*Licen[cs]e
    100% content_match GNU\W*General\W*Public
    100% content_match GNU\W*Affero
    100% content_match GNU\W*Lesser
    100% content_match GNU\W*Free.*Licen[cs]e
    100% content_match Netscape\W*Public
    100% content_match Netscape\W*Licen[cs]e
    100% content_match Academic\W*Free\W*Licen[cs]e
    100% content_match Apple\W*Public\W*Source\W*Licen[cs]e
    100% content_match Creative\W*Commons\W*Attribution
    100% content_match Artistic\W*Licen[cs]e
    100% content_match Common\W*Development.*Licen[cs]e
    100% content_match Educational\W*Community\W*Licen[cs]e
    100% content_match Free\W*Software\W*Foundation

    80%  content_match Open\W*Source
    # 80%  content_match licen[cs]e\W*

    50%  copyright_match ThomsonReuters Reuters Thomson TR EJV Bridge

