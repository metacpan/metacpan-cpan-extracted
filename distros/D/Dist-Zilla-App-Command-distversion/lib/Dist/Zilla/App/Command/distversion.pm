package Dist::Zilla::App::Command::distversion;
use Capture::Tiny 'capture';
 
use strict;
use warnings;
 
our $VERSION = '0.02';
 
use Dist::Zilla::App -command;

sub abstract    { "Prints your dist version on the command line" }
sub description { "Asks dzil what version the dist is on, then prints that" }
sub usage_desc  { "%c" }
sub execute {
    my $self = shift;
	# Something might output.
	capture {
        # https://metacpan.org/source/RJBS/Dist-Zilla-6.010/lib/Dist/Zilla/Dist/Builder.pm#L344,348-352
        $_->before_build       for @{ $self->zilla->plugins_with(-BeforeBuild) };          
		$_->gather_files       for @{ $self->zilla->plugins_with(-FileGatherer) };
		$_->set_file_encodings for @{ $self->zilla->plugins_with(-EncodingProvider) };
		$_->prune_files        for @{ $self->zilla->plugins_with(-FilePruner) };

		$self->zilla->version;
	};
    print $self->zilla->version, "\n";
}

1;

=head1 NAME

Dist::Zilla::App::Command::distversion - report your dist version

=head1 DESCRIPTION

Tries to output the current version of your distribution onto stdout

=head1 SYNOPSIS

    $ dzil distversion
    0.01
