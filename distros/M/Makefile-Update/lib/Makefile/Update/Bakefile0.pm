package Makefile::Update::Bakefile0;
# ABSTRACT: Update bakefile-0.x files list.

use Exporter qw(import);
our @EXPORT = qw(update_bakefile_0);

use strict;
use warnings;

our $VERSION = '0.4'; # VERSION



sub update_bakefile_0
{
    my ($in, $out, $vars) = @_;

    # Variable whose contents is being currently replaced.
    my $var;

    # Hash with files defined for the specified variable as keys and 0 or 1
    # depending on whether we have seen them in the input file as values.
    my %files;

    # Set to 1 if we made any changes.
    my $changed = 0;
    while (<$in>) {
        chomp;

        if (/<set var="(\w+)" hints="files">/ && exists $vars->{$1}) {
            $var = $1;
            %files = map { $_ => 0 } @{$vars->{$var}};
        } elsif (defined $var) {
            local $_ = $_;
            s/<!-- .* -->//;
            s/^\s+//;
            s/\s+$//;
            s{<if [^>]+>}{};
            s{</if>}{};
            if (m{</set>}) {
                # Check if we have any new files.
                #
                # TODO Insert them in alphabetical order.
                while (my ($file, $seen) = each(%files)) {
                    if (!$seen) {
                        # This file was wasn't present in the input, add it.
                        # TODO Use proper indentation.
                        print $out "    $file\n";

                        $changed = 1;
                    }
                }

                undef $var;
            } elsif ($_) {
                if (not exists $files{$_}) {
                    # This file was removed.
                    $changed = 1;
                    next;
                }

                if ($files{$_}) {
                    warn qq{Duplicate file "$_" in the definition of the } .
                         qq{variable "$var" at line $.\n}
                } else {
                    $files{$_} = 1;
                }
            }
        }

        print $out "$_\n";
    }

    $changed
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Makefile::Update::Bakefile0 - Update bakefile-0.x files list.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This is used exclusively to update wxWidgets C<files.bkl> and is probably not
useful outside of wxWidgets project.

    use Makefile::Update::Bakefile0;
    Makefile::Update::upmake('bakefiles/files.bkl', \&update_bakefile_0, $vars);

=head1 FUNCTIONS

=head2 update_bakefile_0

Update file with variable definitions in bakefile-0 format with the data
from the hash ref containing all the file lists.

Takes the (open) file handles of the files to read and to write and the file
lists hash ref as arguments.

Returns 1 if any changes were made.

=head1 SEE ALSO

Makefile::Update

=head1 AUTHOR

Vadim Zeitlin <vz-cpan@zeitlins.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Vadim Zeitlin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
