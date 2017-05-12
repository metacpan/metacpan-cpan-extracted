#---------------------------------------------------------------------
package Dist::Zilla::Plugin::RecommendedPrereqs;
#
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 31 Oct 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Look for comments recommending prerequisites
#---------------------------------------------------------------------

our $VERSION = '4.21';
# This file is part of Dist-Zilla-Plugins-CJM 4.27 (August 29, 2015)


use 5.008;
use Moose;
with(
  'Dist::Zilla::Role::PrereqSource',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
  'Dist::Zilla::Role::FileFinderUser' => {
    method           => 'found_test_files',
    finder_arg_names => [ 'test_finder' ],
    default_finders  => [ ':TestFiles' ],
  },
);

use namespace::autoclean;

#=====================================================================

use CPAN::Meta::Requirements ();
use version ();

sub register_prereqs
{
  my $self  = shift;

  my @sets = (
    [ runtime => 'found_files'      ],
    [ test    => 'found_test_files' ],
  );

  my %runtime;

  for my $fileset (@sets) {
    my ($phase, $method) = @$fileset;

    my %req = map { $_ => CPAN::Meta::Requirements->new } qw(RECOMMEND SUGGEST);

    my $files = $self->$method;

    foreach my $file (@$files) {
      $self->log_debug("Checking " . $file->name);
      my $content = $file->content;

      while ($content =~ /^ [ \t]* \# [ \t]* (RECOMMEND|SUGGEST) [ \t]+ PREREQ:
                          [ \t]* (\S+) (?: [ \t]+ (\S+) )?/mgx) {
        $req{$1}->add_minimum($2, $3 || 0);
      }
    } # end foreach $file

    # we're done, add what we've found
    while (my ($type, $req) = each %req) {
      $req = $req->as_string_hash;

      if ($phase eq 'runtime') {
        $runtime{$type} = $req;
      } else {
        delete $req->{$_} for
            grep { exists $req->{$_} and $runtime{$type}{$_} ge $req->{$_} }
            keys %{ $runtime{$type} || {} };
      }

      $self->zilla->register_prereqs({ phase => $phase, type => "\L${type}s" },
                                     %$req) if %$req;
    }
  } # end foreach $fileset
} # end register_prereqs

#=====================================================================
# Package Return Value:

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::RecommendedPrereqs - Look for comments recommending prerequisites

=head1 VERSION

This document describes version 4.21 of
Dist::Zilla::Plugin::RecommendedPrereqs, released August 29, 2015
as part of Dist-Zilla-Plugins-CJM version 4.27.

=head1 SYNOPSIS

In your F<dist.ini>:

  [RecommendedPrereqs]

In your code:

  # RECOMMEND PREREQ: Foo::Bar 1.0
  # SUGGEST PREREQ:   Foo::Suggested

=head1 DESCRIPTION

If included, this plugin will look for special comments that specify
suggested or recommended prerequisites.  It's intended as a companion
to L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>, which can only
determine required prerequisites.

Each comment must be on a line by itself, and begin with either
S<C<RECOMMEND PREREQ:>> or S<C<SUGGEST PREREQ:>> followed by the
module name.  The name may be followed by the minimum version, which
may in turn be followed by a note explaining the prereq (which will be
ignored).  If the note is present, the version I<must> be present,
even if it's 0.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

The parser currently just looks for lines beginning with a C<#> (which
may be preceded by whitespace).  This means it looks in strings and
here docs, as well as after C<__END__>.  This behavior may be fixed in
the future and should not be depended on.


=for Pod::Coverage
register_prereqs

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Dist-Zilla-Plugins-CJM AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugins-CJM >>.

You can follow or contribute to Dist-Zilla-Plugins-CJM's development at
L<< https://github.com/madsen/dist-zilla-plugins-cjm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
