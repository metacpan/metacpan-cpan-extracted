package Dist::Zilla::Plugin::Test::CPAN::Meta::JSON;
use strict;
use warnings;
# ABSTRACT: release tests for your META.json
our $VERSION = '0.004'; # VERSION

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::FilePruner';
with 'Dist::Zilla::Role::PrereqSource';


sub prune_files {
    my $self = shift;

    # Bail if we find META.json
    my $METAjson = 'META.json';
    foreach my $file (@{ $self->zilla->files }) {
        return if $file->name eq $METAjson;
    }

    # If META.json wasn't found, then prune out the test
    my $test_filename = 'xt/release/meta-json.t';
    foreach my $file (@{ $self->zilla->files }) {
        next unless $file->name eq $test_filename;

        $self->zilla->prune_file($file);
        $self->log_debug([ '%s not found; pruning %s', $METAjson, $file->name ]);
    }
    return;
}

# Register the release test prereq as a "develop requires"
# so it will be listed in "dzil listdeps --author"
sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    {
      type  => 'requires',
      phase => 'develop',
    },
    'Test::CPAN::Meta::JSON' => '0.16',
  );
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::CPAN::Meta::JSON - release tests for your META.json

=head1 VERSION

version 0.004

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::CPAN::Meta::JSON]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file if F<META.json> is in your dist:

    xt/release/meta-json.t - a standard Test::CPAN::Meta::JSON test

See L<Test::CPAN::Meta::JSON> for what this test does.

=for Pod::Coverage prune_files register_prereqs

=for test_synopsis 1;
__END__

=head1 AVAILABILITY

The project homepage is L<http://p3rl.org/Dist::Zilla::Plugin::Test::CPAN::Meta::JSON>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Test::CPAN::Meta::JSON/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-Test-CPAN-Meta-JSON>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-Test-CPAN-Meta-JSON.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-Test-CPAN-Meta-JSON/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ xt/release/meta-json.t ]__
#!perl

use Test::CPAN::Meta::JSON;
meta_json_ok();
