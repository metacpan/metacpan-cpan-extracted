package inc::CheckGitConfig;
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

# TODO: in future versions of MakeMaker::Awesome, we can do all this right
# from dist.ini, so we don't have to subclass. pester ether.

around _build_MakeFile_PL_template => sub {
    my $orig = shift;
    my $self = shift;

my $git_check = <<GIT_CHECK;
require File::Spec;
die 'Unable to run "git config --list". Do you need to add a ~/.gitconfig file?'
    if system('git config --list >'.File::Spec->devnull);

GIT_CHECK

    my $template = $self->$orig(@_);
    $template =~ s/(?<=use warnings;\n\n)/$git_check/m;
    return $template;
};

after register_prereqs => sub {
    my $self = shift;

    $self->zilla->register_prereqs(
        { phase => 'configure' },
        'File::Spec' => 0,
    );
};

1;
