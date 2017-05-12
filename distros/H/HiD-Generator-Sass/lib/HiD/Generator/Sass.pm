package HiD::Generator::Sass;
$HiD::Generator::Sass::VERSION = '0.004';
# ABSTRACT: Compile Sass files to CSS

=head1 SYNOPSIS

In F<_config.yml>:

   plugins:
        - Sass
   sass:
        sources:
            - _sass/*.scss
        output:  css/

=head1 DESCRIPTION

HiD::Generator::Sass is a plugin for the HiD static blog system
that uses L<CSS::Sass> to compile your sass files
into css.

=head1 CONFIGURATION PARAMETERS

=head2 sources

List of sass sources to compile. File globs can be used.

=head2 output

Site sub-directory where the compiled css files will be put.

=cut

use Moose;
with 'HiD::Generator';
use File::Find::Rule;
use Path::Tiny;
use CSS::Sass;

use 5.014;

use HiD::VirtualPage;

sub generate {
  my($self, $site) = @_;

  my $src = $site->config->{sass}{sources};
  # allow for a single source
  my @sass_sources = ref $src ? @$src : $src ? ( $src ) : ();

  my $sass_style;
  $sass_style = eval $site->config->{sass}{sass_style} if $site->config->{sass}{sass_style};

  # give it a default value is nothing is passed
  $sass_style //= SASS_STYLE_NESTED;

  my $sass = CSS::Sass->new( output_style  => $sass_style );

  foreach my $file ( map { glob $_ } @sass_sources) {
    $site->INFO("* Compiling sass file - " . $file);
    my $css = $sass->compile_file($file);
    my $filename = path($file)->basename('.scss');

    my $css_file = HiD::VirtualPage->new({
      content => $css,
      output_filename => path( $site->destination,
                         $site->config->{sass}{output}, 
                         $filename . '.css')->stringify
    });

    $site->INFO("* Publishing " . $css_file->output_filename);

    $site->add_object($css_file);
  }

  $site->INFO("* Compiled sass files successfully!");
}

__PACKAGE__->meta->make_immutable;
1;
