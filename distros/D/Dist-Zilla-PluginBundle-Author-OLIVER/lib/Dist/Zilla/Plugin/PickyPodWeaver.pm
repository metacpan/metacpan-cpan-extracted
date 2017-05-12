package Dist::Zilla::Plugin::PickyPodWeaver;
BEGIN {
  $Dist::Zilla::Plugin::PickyPodWeaver::VERSION = '1.122720';
}

use Moose;
with 'Dist::Zilla::Role::Plugin';
extends 'Dist::Zilla::Plugin::PodWeaver';

override 'found_files' => sub {
    return [ grep {$_->content =~ m/^# ABSTRACT: /m} @{super()} ];
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
