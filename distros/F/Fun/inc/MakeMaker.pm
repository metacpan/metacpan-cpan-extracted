package inc::MakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

around _build_MakeFile_PL_template => sub {
    my $orig = shift;
    my $self = shift;
    my $tmpl = $self->$orig;
    return $tmpl . <<'TMPL'
use Devel::CallParser 'callparser1_h';
open my $fh, '>', 'callparser1.h' or die "Couldn't write to callparser1.h";
$fh->print(callparser1_h);
TMPL
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
