#!/usr/bin/env perl

use 5.010;
use strict; # (automatic since 5.12.0) 
use warnings; # (automatic since 5.16.0) 
use feature 'say'; # (automatic since 5.36.0)
use YAML::XS qw(LoadFile); 
use Data::Dumper::Concise;
use Mail::Alias::LocalFile;

# select the desired file for demonstration purposes
#  my $alias_file_path = 'aliases.yml'; # has intentional circular references
my $alias_file_path = 'good_aliases.yml'; # an example with all good entrires
 
my $aliases = load_aliases_file();

# Create a new resolver object - using Moo-style named parameters
my $resolver = Mail::Alias::LocalFile->new(aliases => $aliases);

# Resolve email addresses
my @recipients = ();
if (@ARGV) {
    @recipients = @ARGV;
}
else {
    say '';
    say "ERROR: No email recipients and/or aliases were provided";
    say '';
}

# Returns a hash_ref holding ivarious useful keys and values
my $result = $resolver->resolve_recipients(\@recipients);

my $recipients           = $result->{recipients};
my $warning              = $result->{warning};
my $alias_file_contents  = $result->{aliases};
my $original_input       = $result->{original_input};
my $processed_aliases    = $result->{processed_aliases};
my $uniq_email_addresses = $result->{uniq_email_addresses};
my $expanded_addresses   = $result->{expanded_addresses};
my $circular_references  = $result->{circular_references};


say '';
say "recipients: $recipients";

if ( @$circular_references ) {
    say 'Warning: the aliases file contains circular references';
    foreach my $item ( @{$circular_references} ) {
        say "    $item";
    }

}

if ( @$warning ) {
    say '';
    say 'warning';
    foreach my $item ( @{$warning} ) {
        say "    $item";
    }
    say '';
    say "Alias File Contents";
    say Dumper( $alias_file_contents );
    say '';
    say 'Original Input';
    foreach my $item ( @{$original_input} ) {
        say "    $item";
    }
    say '';
}

# uncomment for troubleshooting
  say "=============== START ===============================";
  say "result";
  say Dumper( $result );
  say "================ END  ===============================";

sub load_aliases_file {

    # say "Loading aliases file from $alias_file_path";

    # load the aliases.yml file

    # will become a hashref with an alias as a key
    # and values that can be more aliases or actual
    # email addresses

    eval { $aliases = LoadFile($alias_file_path); };

    if ($@) {
        say '';
        say "The aliases.yml file did not load";
        say "ERROR: $@";
        say "ERROR: $!";
        say '';
        exit;
    }
    return ($aliases);
}

=head1 NAME

expand_aliases.pl - Resolves email aliases from a YAML configuration file

=head1 SYNOPSIS

  ./expand_aliases.pl email@example.com team-alias some-group

=head1 DESCRIPTION

This script expands email aliases defined in a YAML file into a list of actual email addresses.
It helps in managing mailing lists and group communications by maintaining aliases in a central
configuration file rather than having to remember individual email addresses.

The script uses the C<Mail::Alias::LocalFile> module to handle the expansion of aliases,
including detection and warning about circular references.

=head1 REQUIREMENTS

=over 4

=item * Perl 5.10.0 or newer

=item * YAML::XS

=item * Data::Dumper::Concise

=item * Mail::Alias::LocalFile

=back

=head1 CONFIGURATION

The script looks for aliases in a YAML file. By default, it uses 'aliases.yml', but the path
can be modified by changing the C<$alias_file_path> variable in the script.

Alternative configurations are commented out in the script:

  # my $alias_file_path = 'aliases.json';
  # my $alias_file_path = 'good_aliases.yml';

=head2 Aliases File Format

The aliases file should be in YAML format with the following structure:

  alias1:
    - user1@example.com
    - user2@example.com
  alias2: user3@example.com, alias1, mta_postmaster

Aliases can refer to other aliases, which will be expanded recursively.

=head1 USAGE

  ./expand_aliases.pl [email addresses and/or aliases...]

=head1 OUTPUT

The script outputs:

=over 4

=item * List of expanded recipients

=item * Warnings about circular references (if any)

=item * Original input list

=item * Detailed debug information (when the debug section is uncommented)

=back

=head1 TROUBLESHOOTING

Debug information can be enabled by uncommenting the troubleshooting section at the end of the script:

  say "=============== START ===============================";
  say "result";
  say Dumper( $result );
  say "================ END  ===============================";

=head1 DIAGNOSTICS

=over 4

=item * C<ERROR: No email recipients and/or aliases were provided>

The script was called without any arguments. You need to provide at least one email address or alias.

=item * C<The aliases.yml file did not load>

There was an error loading the aliases file. Make sure the file exists and contains valid YAML.

=item * C<Warning: the aliases file contains circular references>

The aliases file contains circularity where alias definitions form a loop. This could cause infinite
recursion if not handled properly.

=back

=head1 EXAMPLES

=over 4

=item * Expand a single alias:

  ./expand_aliases.pl developers

=item * Expand multiple aliases and individual addresses:

  ./expand_aliases.pl developers managers john@example.com

=back

=head1 AUTHOR

Contact the original author for more information about this script.

=head1 SEE ALSO

L<Mail::Alias::LocalFile>, L<YAML::XS>

=cut
