#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 05/12/2009 09:54:18 PM PDT
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools::SpecData::New;

use Moose;
use MooseX::Types::Moose ':all';

use namespace::autoclean;
#use autodie qw{ system };

#use Fedora::App::MaintainerTools::Types ':all';

use DateTime;
use File::Basename;
use List::MoreUtils qw{ any uniq };
use Path::Class;
use Pod::POM;
use Pod::POM::View::Text;
use Text::Autoformat;

extends 'Fedora::App::MaintainerTools::SpecData';

our $VERSION = '0.006';

# debugging
#use Smart::Comments '###', '####';

sub _build_name 	 { 'perl-' . shift->dist }
sub _build__requires { my %x = shift->mm->full_rpm_requires; \%x }

sub _build__build_requires {
	my $self = shift @_;
	my %reqs = $self->mm->full_rpm_build_requires;

	# force ExtUtils::MakeMaker
	$reqs{'perl(ExtUtils::MakeMaker)'} = 0
		if not exists $reqs{'perl(ExtUtils::MakeMaker)'};

	return \%reqs;
}

sub _build__changelog {

    [ "- specfile by Fedora::App::MaintainerTools $Fedora::App::MaintainerTools::VERSION" ]
}

sub _build_version { shift->mm->data->{version} }
sub _build_summary { shift->mm->data->{abstract} }

#############################################################################
# description

#has description => (is => 'rw', isa => Str, lazy_build => 1);

# this is largely stolen from CPANPLUS::Dist::RPM...  in need of some serious
# refactoring but works for now.

#
# given a cpanplus::module, try to extract its description from the
# embedded pod in the extracted files. this would be the first paragraph
# of the DESCRIPTION head1.
#
sub _build_description {
    my $self = shift @_;

    my $module = $self->module;

    # where tarball has been extracted
    my $path   = dirname $module->_status->extract;
    my $parser = Pod::POM->new;

    my @docfiles =
        map  { "$path/$_" }               # prepend extract directory
        sort { length $a <=> length $b }  # sort by length
        grep { /\.(pod|pm)$/ }            # filter potentially pod-containing
        @{ $module->_status->files };     # list of embedded files

    my $desc;

    # parse file, trying to find a header
    DOCFILE:
    foreach my $docfile ( @docfiles ) {

        # extract pod; the file may contain no pod, that's ok
        my $pom = $parser->parse_file($docfile);
        next DOCFILE unless defined $pom;

        HEAD1:
        foreach my $head1 ($pom->head1) {

            next HEAD1 unless $head1->title eq 'DESCRIPTION';

            my $pom  = $head1->content;
            my $text = $pom->present('Pod::POM::View::Text');

            # limit to 3 paragraphs at the moment
           my @paragraphs = (split /\n\n/, $text)[0..2];
            #$text = join "\n\n", @paragraphs;
            $text = q{};
            for my $para (@paragraphs) { $text .= $para || ''}

            # autoformat and return...
            return autoformat $text, { all => 1 };
        }
    }

    return '%{summary}.';
}

#############################################################################
# license

# this is largely stolen from CPANPLUS::Dist::RPM...  in need of some serious
# refactoring but works for now.

has license_map => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::Hash' ],
    is => 'ro', isa => 'HashRef[Str]', lazy_build => 1,
    provides => { get => 'license_shortname' },
);

has license_comment => (is => 'rw', isa => 'Maybe[Str]', lazy_build => 1);

sub _build_license_comment { undef }

sub _build_license_map {

    return {

        # classname                         => shortname
        'Software::License::AGPL_3'         => 'AGPLv3',
        'Software::License::Apache_1_1'     => 'ASL 1.1',
        'Software::License::Apache_2_0'     => 'ASL 2.0',
        'Software::License::Artistic_1_0'   => 'Artistic',
        'Software::License::Artistic_2_0'   => 'Artistic 2.0',
        'Software::License::BSD'            => 'BSD',
        'Software::License::FreeBSD'        => 'BSD',
        'Software::License::GFDL_1_2'       => 'GFDL',
        'Software::License::GPL_1'          => 'GPL',
        'Software::License::GPL_2'          => 'GPLv2',
        'Software::License::GPL_3'          => 'GPLv3',
        'Software::License::LGPL_2_1'       => 'LGPLv2',
        'Software::License::LGPL_3_0'       => 'LGPLv3',
        'Software::License::MIT'            => 'MIT',
        'Software::License::Mozilla_1_0'    => 'MPLv1.0',
        'Software::License::Mozilla_1_1'    => 'MPLv1.1',
        'Software::License::Perl_5'         => 'GPL+ or Artistic',
        'Software::License::QPL_1_0'        => 'QPL',
        'Software::License::Sun'            => 'SPL',
        'Software::License::Zlib'           => 'zlib',
    };
}

sub _build_license {
    my $self = shift @_;

    Class::MOP::load_class('File::Find::Rule');

    #my $module = $self->parent;
    my $module = $self->module;

    my $lic_comment = q{};

    # First, check what CPAN says
    my $cpan_lic = $module->details->{'Public License'};

    ### $cpan_lic

    # then, check META.yml (if existing)
    my $extract_dir = dir $module->extract;
    my $meta_file   = file $extract_dir, 'META.yml';
    my @meta_lics;

    if (-e "$meta_file" && -r _) {

        my $meta = $meta_file->slurp;
        @meta_lics =
            Software::LicenseUtils->guess_license_from_meta_yml($meta);
    }

    # FIXME we pretty much just ignore the META.yml license right now

    ### @meta_lics

    # then, check the pod in all found .pm/.pod's
    my $rule = File::Find::Rule->new;
    my @pms = File::Find::Rule
        ->or(
            File::Find::Rule->new->directory->name('blib')->prune->discard,
            File::Find::Rule->new->file->name('*.pm', '*.pod')
            )
        ->in($extract_dir)
        ;
    my %pm_lics;

    for my $file (@pms) {

        $file = file $file;
        #my $text = file($file)->slurp;
        my $text = $file->slurp;
        my @lics = Software::LicenseUtils->guess_license_from_pod($text);

        ### file: "$file"
        ### @lics

        #push @pm_lics, @lics;
        $pm_lics{$file->relative($extract_dir)} = [ @lics ]
            if @lics > 0;
    }

    ### %pm_lics

    my @lics;

    for my $file (sort keys %pm_lics) {

       my @file_lics = map { $self->license_shortname($_) } @{$pm_lics{"$file"}};

       $lic_comment .= "# $file -> " . join(q{, }, @file_lics) . "\n";
       push @lics, @file_lics;
    }

    # FIXME need to sort out the licenses here
    @lics = uniq @lics;

    ### $lic_comment
    ### @lics

    if (@lics > 0) {
        #$self->status->license(join(' or ', @lics));
        $self->license_comment($lic_comment);
        return join(' or ', @lics);
    }

    #$self->status->license($DEFAULT_LICENSE);
    $self->license_comment("# license auto-determination failed\n");
    #$self->status->license('CHECK(GPL+ or Artistic)');
    return 'CHECK(GPL+ or Artistic)';
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools::SpecData::New - Prepare data for the generation
of a new specfile

=head1 SYNOPSIS

	use <Module::Name>;
	# Brief but working code example(s) here showing the most common usage(s)

	# This section will be as far as many users bother reading
	# so make it as educational and exemplary as possible.


=head1 DESCRIPTION

This package extends L<Fedora::App::MaintainerTools::SpecData> to gather data
from the CPAN (and a dist's META.yml) to generate a RPM specfile.

=head1 ATTRIBUTES

We define the additional attributes:

=head2 description


=head1 OVERRIDDEN BUILDERS

We override a number of builder methods to provide the correct data.  (If
you're really interested in them, you should probably read the source :))

=head1 SEE ALSO

L<Fedora::App::MaintainerTools>, L<Fedora::App::MaintainerTools::SpecData>,
L<CPANPLUS::Dist::RPM>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut



