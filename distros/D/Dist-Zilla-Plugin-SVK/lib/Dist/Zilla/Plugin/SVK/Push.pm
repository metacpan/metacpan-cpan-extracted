use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::SVK::Push;
# ABSTRACT: push current branch

use SVK;
use SVK::XD;
use SVK::Util qw/find_dotsvk/;
use File::Basename;

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ ArrayRef Str };
use String::Formatter method_stringf => {
  -as => '_format_tag',
  codes => {
    d => sub { require DateTime;
               DateTime->now->format_cldr($_[1] || 'dd-MMM-yyyy') },
    n => sub { "\n" },
    N => sub { $_[0]->name },
    v => sub { $_[0]->version },
  },
};

with 'Dist::Zilla::Role::AfterRelease';

# sub mvp_multivalue_args { qw(push_to) }

# -- attributes

has push_to => (
  is   => 'rw',
  isa  => 'Str',
  lazy => 1,
  default => "//mirror",
);

sub after_release {
    my $self = shift;
	# push everything on remote branch
	$self->log("pushing to remote");
	system( 'svk push' );
	$self->log_debug( "The local changes" );
	my $tagger = $self->zilla->plugin_named('SVK::Tag');
	my $project = $tagger->project || $self->zilla->name;
	my $project_dir = lc $project;
	$project_dir =~ s/::/-/g;
	my $tag_dir = $tagger->tag_directory;
	my $firstpart = qr|^/([^/]*)|;
	my $info = qx "svk info";
	$info =~ m/^.*\n[^\/]*(\/.*)$/m; my $depotpath = $1;
	( my $depotname = $depotpath ) =~ s|$firstpart.*$|$1|;
	$depotpath = dirname( $depotpath ) until basename( $depotpath ) eq
		$project_dir or basename( $depotpath ) eq $depotname
			or basename( $depotpath ) eq '/';
	my $remote = $self->push_to;
	my $tag_format = $tagger->tag_format;
	my $tag_message = $tagger->tag_message;
	my $tag = _format_tag($tag_format, $self->zilla);
	my $message = _format_tag($tag_message, $self->zilla);
	my $localtagpath = "$depotpath/$tag_dir/$tag";
	my $remotetagpath = "$remote/$project_dir/$tag_dir/$tag";
	system( "svk mkdir $remotetagpath -m $message" );
	system( "svk smerge --baseless $localtagpath $remotetagpath -m $message" );
	# system( "svk cp $localtagpath $remotetagpath -m $message" );
	$self->log_debug( "The tags too" );
}

1;


=pod

=head1 NAME

Dist::Zilla::Plugin::SVK::Push - push current branch

=head1 VERSION

version 0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [SVK::Push]
    push_to = //mirror      ; this is the default, the project is underneath

=head1 DESCRIPTION

Once the release is done, this plugin will push current svk branch to
remote that it was copied from, but the associated tags need the mirror name.

The plugin accepts the following options:

=over 4

=item * 

push_to - the name of the remote repo to push to. The default is F<//mirror>. The project and tags subdirectories underneath the remote are from F<Tag.pm>, 

=back

=for Pod::Coverage after_release
    mvp_multivalue_args

=head1 AUTHOR

Dr Bean <drbean at (a) cpan dot (.) org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dr Bean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

