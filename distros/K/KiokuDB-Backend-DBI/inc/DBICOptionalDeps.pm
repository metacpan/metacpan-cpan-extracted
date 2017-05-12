package inc::DBICOptionalDeps;
use Moose;

use DBIx::Class::Optional::Dependencies;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my ($self) = @_;

    my $template = super();

    my $injected = <<'INJECT';
require DBIx::Class::Optional::Dependencies;

$WriteMakefileArgs{PREREQ_PM} = {
    %{ $WriteMakefileArgs{PREREQ_PM} || {} },
    %{ DBIx::Class::Optional::Dependencies->req_list_for ('deploy') },
};

INJECT

    $template =~ s{(?=WriteMakefile\s*\()}{$injected};

    return $template;
};

around register_prereqs => sub {
    my $orig = shift;
    my $self = shift;
    $self->$orig(@_);
    $self->zilla->register_prereqs(
        { phase => 'develop' },
        %{ DBIx::Class::Optional::Dependencies->req_list_for('deploy') }
    );
    return
};

__PACKAGE__->meta->make_immutable;

