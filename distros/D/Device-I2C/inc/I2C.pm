package inc::I2C;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub {
    my ($self) = @_;
    my $template = super();
    our @DIR = qw(.);
    our @LIBS = qw();
    return +{
        %{ $template },
        LIBS          => [join(' ', map { "-l$_" } @LIBS) . ' '],
        DEFINE        => '',
        INC           => join(' ', map { "-I$_" } @DIR),
    };
};

override _build_MakeFile_PL_template => sub {
    my ($self) = @_;
    my $template = super();

    # Extra code append for Makefile.PL for XS binding
    $template .= <<'TEMPLATE';
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Device::I2C',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
TEMPLATE
    return $template;
};

__PACKAGE__->meta->make_immutable;
1;
