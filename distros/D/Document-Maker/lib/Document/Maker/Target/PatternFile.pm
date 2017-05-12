package Document::Maker::Target::PatternFile;

use strict;
use warnings;

use Moose;

use Document::Maker::Source::File;
use Document::Maker::Target::File;
use Document::Maker::Dependency;

with map { "Document::Maker::Role::$_" } qw/Component Target TargetMaker Dependency/;

has script => qw/is rw/;
has file_target => qw/is ro/, handles => [qw/name freshness should_make fresh file dependency/];
has source_file => qw/is ro/;
has nickname => qw/is ro required 1/;
has target_pattern => qw/is ro isa Document::Maker::Pattern required 1/;
has source_pattern => qw/is ro isa Document::Maker::Pattern required 1/;

sub BUILD {
    my $self = shift;
    my %BUILD = %{ $_[0] };

    my $nickname = $self->{nickname} = $self->source_pattern->nickname($self->nickname);
    my $source_file = $self->{source_file} = Document::Maker::Source::File->new(maker => $self->maker, file => $self->source_pattern->substitute($nickname));
    my $name = $self->target_pattern->substitute($nickname);

    my $dependency = $BUILD{dependency} || Document::Maker::Dependency->new(maker => $self->maker);
    $dependency->add_dependency($source_file);
    my $file_target = Document::Maker::Target::File->new(maker => $self->maker, name => $name, dependency => $dependency);
    $self->{file_target} = $file_target;

    $self->log->debug("New pattern target file: $nickname -> $name ", $source_file->file);
}

sub can_make {
    my $self = shift;
    my $name = shift;
    return $self if $name eq $self->name;
    return undef;
}

sub make {
    my $self = shift;
    $self->dependency->make($self);
    $self->execute if $self->script;
}

sub execute {
    my $self = shift;
    die "Can't execute without a script" unless $self->script;
    $self->script->($self, $self->file, $self->source_file->file);
}

1;
