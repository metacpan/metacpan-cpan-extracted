package inc::SmapsTinyMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my ($self) = @_;
    my $template = super();

    my $maybe_cc = <<'MAYBE_CC';
unless (can_cc()) {
    # Same parameters as http://cpansearch.perl.org/src/GBARR/Scalar-List-Utils-1.23/Makefile.PL
    $WriteMakefileArgs{XS}     = {};
    $WriteMakefileArgs{C}      = [];
    $WriteMakefileArgs{OBJECT} = '';
}
MAYBE_CC

    $template =~ s/(^my \{\{ \$WriteMakefileArgs \}\})/$1\n$maybe_cc/m;

    $template .= <<'TEMPLATE';
# Copied from http://cpansearch.perl.org/src/GBARR/Scalar-List-Utils-1.23/Makefile.PL
sub can_cc {

    foreach my $cmd (split(/ /, $Config::Config{cc})) {
        my $_cmd = $cmd;
        return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

        for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
            my $abs = File::Spec->catfile($dir, $_[1]);
            return $abs if (-x $abs or $abs = MM->maybe_command($abs));
        }
    }

    return;
}
TEMPLATE

    return $template;
};

__PACKAGE__->meta->make_immutable;
