use 5.026;
use warnings;

package Dist::Zilla::PluginBundle::Author::AJNN::Readme;
# ABSTRACT: Build a README file for AJNN's distributions
$Dist::Zilla::PluginBundle::Author::AJNN::Readme::VERSION = '0.01';

use Dist::Zilla;
use Dist::Zilla::File::FromCode;
use Encode;
use Moose;
use namespace::autoclean;
use Pod::Elemental;
use Pod::Text;

use Pod::Weaver::PluginBundle::Author::AJNN::License;

with 'Dist::Zilla::Role::FileGatherer';


sub gather_files {
	my ($self, $arg) = @_;
	
	$self->add_file(
		Dist::Zilla::File::FromCode->new(
			name => 'README',
			code => sub { $self->_readme },
		),
	);
}


sub _readme {
	my ($self) = @_;
	
	return join "\n\n", (
		$self->_readme_header,
		$self->_readme_install,
		$self->_readme_license,
	);
}


sub _readme_header {
	my ($self) = @_;
	
	my $main_module  = $self->_main_module_name;
	my $dist_version = $self->zilla->version;
	my $dist_name    = $self->zilla->name;
	my $trial_rel    = $self->zilla->is_trial ? " (TRIAL RELEASE)" : "";
	
	my $description = $self->_main_module_description;
	$description =~ s/\n\n.*$//;  # only keep the first paragraph
	
	return <<END;
$main_module $dist_version$trial_rel

$description

More information about this software:
https://metacpan.org/release/$dist_name
END
}


sub _readme_install {
	my ($self) = @_;
	
	my $main_module = $self->_main_module_name;
	
	return <<END;
INSTALLATION

The recommended way to install this Perl module distribution is directly
from CPAN with whichever tool you use to manage your installation of Perl.
For example:

  cpanm $main_module

If you already have downloaded the distribution, you can alternatively
point your tool directly at the archive file or the directory:

  cpanm .

You can also install the module manually by following these steps:

  perl Makefile.PL
  make
  make test
  make install

See https://www.cpan.org/modules/INSTALL.html for general information
on installing CPAN modules.
END
}


sub _readme_license {
	my ($self) = @_;
	
	my $notice = Pod::Weaver::PluginBundle::Author::AJNN::License->notice_maybe_mangled(
		$self->zilla->license,
		$self->zilla->authors,
	);
	return "COPYRIGHT AND LICENSE\n\n" . $notice;
}


sub _main_module_name {
	my ($self) = @_;
	
	my $name = $self->zilla->main_module->name;
	$name =~ s{^lib/|\.pm$}{}g;
	$name =~ s{/}{::}g;
	return $name;
}

	
sub _main_module_description {
	my ($self) = @_;
	
	my $pod = $self->zilla->main_module->content;
	$pod = Encode::encode( 'UTF-8', $pod, Encode::FB_CROAK );
	my $document = Pod::Elemental->read_string( $pod );
	my $desc_found;
	for my $element ($document->children->@*) {
		if ($desc_found) {
			next unless $element->isa('Pod::Elemental::Element::Generic::Text');
			my $parser = Pod::Text->new( indent => 0 );
			$parser->output_string( \( my $text ) );
			$parser->parse_string_document( "=pod\n\n" . $element->content );
			$text =~ s/^\s+//;
			$text =~ s/\s+$//;
			return $text || $self->zilla->abstract;
		}
		$desc_found = $element->isa('Pod::Elemental::Element::Generic::Command')
		              && $element->command eq 'head1'
		              && $element->content =~ m/\s*DESCRIPTION\s*/;
	}
	
	return $self->zilla->abstract;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::AJNN::Readme - Build a README file for AJNN's distributions

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Provides a F<README> file which only contains the most important information
for someone who may have extracted the distribution archive, but is unsure
what it is and what to do with it.

In particular, the following content is included in the F<README>:

=over

=item * main module name

=item * distribution version number

=item * first paragraph of the distribution POD's description section
(or the abstract, if the description can't be found or is empty)

=item * URL of the distribution's home page on MetaCPAN

=item * installation instructions (for both tools and manual)

=item * author identification

=item * license statement

=back

It may be assumed that people who are already familiar with Perl and
its ecosystem won't usually read the F<README> accompanying a CPAN
distribution. They typically get all they need to know from MetaCPAN,
and are accustomed to C<cpanm> and other tools. Non-Perl people, however,
might not know how to install a Perl distribution or how to access the
documentation. In my opinion, I<this> is the information a CPAN distro
F<README> really needs to provide.

Identification of the module, on the other hand, may be kept very brief.
A license file is included with the distribution, so stating the license
is generally not required; however, this plugin will pick up any mangling
done by L<Pod::Weaver::PluginBundle::Author::AJNN::License>.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::AJNN>

L<Pod::Weaver::PluginBundle::Author::AJNN::License>

L<Dist::Zilla::Plugin::Readme>

L<Dist::Zilla::Plugin::Readme::Brief>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

Arne Johannessen has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
