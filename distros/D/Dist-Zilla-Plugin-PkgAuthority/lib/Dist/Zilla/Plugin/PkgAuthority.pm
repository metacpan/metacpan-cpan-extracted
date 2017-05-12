package Dist::Zilla::Plugin::PkgAuthority;

$Dist::Zilla::Plugin::PkgAuthority::VERSION   = '0.05';
$Dist::Zilla::Plugin::PkgAuthority::AUTHORITY = 'cpan:MANWAR';

use Moose;

with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => { default_finders => [ ':InstallModules', ':ExecFiles' ] },
    'Dist::Zilla::Role::PPI',
);

use namespace::autoclean;

has die_on_existing_authority => (is => 'ro', isa => 'Bool',  default => 0);
has pause_id                  => (is => 'ro', isa => 'Str',  required => 1);

sub munge_files {
    my ($self) = @_;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;

    if ($file->is_bytes) {
        $self->log_debug($file->name . " has 'bytes' encoding, skipping...");
        return;
    }

    if ($file->name =~ /\.pod$/) {
        $self->log_debug($file->name . " is a pod file, skipping...");
        return;
    }

    return $self->munge_perl($file);
}

sub munge_perl {
    my ($self, $file) = @_;

    my $document = $self->ppi_document_for_file($file);

    my $package_stmts = $document->find('PPI::Statement::Package');
    unless ($package_stmts) {
        $self->log_debug([ 'skipping %s: no package statement found', $file->name ]);
        return;
    }

    if ($self->document_assigns_to_variable($document, '$AUTHORITY')) {
        if ($self->die_on_existing_authority) {
            $self->log_fatal([ 'existing assignment to $AUTHORITY in %s', $file->name ]);
        }

        $self->log([ 'skipping %s: assigns to $AUTHORITY', $file->name ]);
        return;
    }

    my %seen_pkg;

    my $authority = sprintf("cpan:%s", $self->pause_id);

    my $munged = 0;
    for my $stmt (@$package_stmts) {
        my $package = $stmt->namespace;
        if ($seen_pkg{ $package }++) {
            $self->log([ 'skipping package re-declaration for %s', $package ]);
            next;
        }

        if ($stmt->content =~ /package\s*(?:#.*)?\n\s*\Q$package/) {
            $self->log([ 'skipping private package %s in %s', $package, $file->name ]);
            next;
        }

        $self->log("non-ASCII package name is likely to cause problems")
            if $package =~ /\P{ASCII}/;

        my $perl = "\$$package\::AUTHORITY\x20=\x20'$authority';";
        $self->log_debug([ 'adding $AUTHORTY assignment to %s in %s', $package, $file->name ]);

        my $blank;
        {
            my $curr = $stmt;
            while (1) {
                # avoid bogus locations due to insert_after
                $document->flush_locations if $munged;
                my $curr_line_number = $curr->line_number + 1;
                my $find = $document->find(
                    sub {
                        my $line = $_[1]->line_number;
                        return $line > $curr_line_number ? undef : $line == $curr_line_number;
                    });

                last unless $find and @$find == 1;

                if ($find->[0]->isa('PPI::Token::Comment')) {
                    $curr = $find->[0];
                    next;
                }

                if ("$find->[0]" =~ /\A\s*\z/) {
                    $blank = $find->[0];
                }

                last;
            }
        }

        $perl = $blank ? "\n$perl\n" : "\n$perl";
        my $bogus_token = PPI::Token::Comment->new($perl);

        if ($blank) {
            Carp::carp("error inserting authority in " . $file->name)
                unless $blank->insert_after($bogus_token);
            $blank->delete;
        } else {
            Carp::carp("error inserting authority in " . $file->name)
                unless $stmt->insert_after($bogus_token);
        }

        $munged = 1;
    }

    # the document is no longer correct; it must be reparsed before it can be used again
    $file->encoded_content($document->serialize) if $munged;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PkgAuthority - Add a $AUTHORITY to your packages.

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

in dist.ini

  [PkgAuthority]
  pause_id = <PAUSEID>

=head1 DESCRIPTION

This plugin  will add line like the following to each package in each Perl module
or program (more or less) within the distribution:

  $MyModule::AUTHORITY = 'cpan:PAUSEID';

It will skip any package declaration that includes a newline between the C<package>
keyword and the package name, like:

  package
    Foo::Bar;

This sort of declaration  is also ignored by the CPAN toolchain, and is typically
used when doing monkey patching or other tricky things.

=head1 ATTRIBUTES

=head2 die_on_existing_authority

If true, then when C<Dist::Zilla::Plugin::PkgAuthority> sees an existing C<$AUTHORITY>
assignment, it  will throw an exception rather than skip the file. This attribute
defaults to false.

Also note that assigning to C<$AUTHORITY> before the module has finished compiling
can  lead  to  confused  behavior with attempts to determine whether a module was
successfully loaded on perl v5.8.

=head2 finder

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
modules to edit.  The default value is C<:InstallModules> and C<:ExecFiles>;
this option can be used more than once.

Other predefined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> and
L<[FileFinder::Filter]|Dist::Zilla::Plugin::FileFinder::Filter> plugins.

=head1 AUTHOR

Mohammad S Anwar C<< <mohammad.anwar AT yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Dist-Zilla-Plugin-PkgAuthority>

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Authority>

=head1 ACKNOWLEDGEMENT

Inspired by the package L<Dist::Zilla::Plugin::PkgVersion> by RJBS,

=head1 BUGS

Please report any bugs or feature requests to C<bug-dist-zilla-plugin-pkgauthority at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-PkgAuthority>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dist::Zilla::Plugin::PkgAuthority

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-PkgAuthority>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-PkgAuthority>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-PkgAuthority>

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-PkgAuthority/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
