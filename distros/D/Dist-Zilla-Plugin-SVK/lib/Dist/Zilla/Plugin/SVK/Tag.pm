use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::SVK::Tag;
# ABSTRACT: tag the new version

use SVK;
use SVK::XD;
use SVK::Util qw/find_dotsvk/;
use List::MoreUtils qw/any/;
use File::Basename;

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };
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

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::AfterRelease';


# -- attributes

has tag_format  => ( ro, isa=>Str, default => 'v%v' );
has tag_message => ( ro, isa=>Str, default => 'v%v' );
has project => ( ro, isa=>Str );
has tag_directory => ( ro, isa=>Str, default => 'tags' );

# -- role implementation

sub before_release {
    my $self = shift;
	my $firstpart = qr|^/([^/]*)|;
	my $info = qx "svk info";
	$info =~ m/^.*\n[^\/]*(\/.*)$/m; my $depotpath = $1;
	( my $depotname = $depotpath ) =~ s|$firstpart.*$|$1|;
	my $project = $self->project || $self->zilla->name;
	my $project_dir = lc $project;
	$project_dir =~ s/::/-/g;
	my $tag_dir = $self->tag_directory;

    # Make sure a tag with the new version doesn't exist yet:
    my $tag = _format_tag($self->tag_format, $self->zilla);
	my $output = qx "svk ls /$depotname/$project_dir/$tag_dir";
	my @tags = split "\n", $output;
    $self->log_fatal("tag $tag already exists") if any { m/^$tag/ } @tags;
}

sub after_release {
    my $self = shift;
	my $firstpart = qr|^/([^/]*)|;
	my $info = qx "svk info";
	$info =~ m/^.*\n[^\/]*(\/.*)$/m; my $depotpath = $1;
	( my $depotname = $depotpath ) =~ s|$firstpart.*$|$1|;
	my $project = $self->project || $self->zilla->name;
	my $project_dir = lc $project;
	$project_dir =~ s/::/-/g;
	my $tag_dir = $self->tag_directory;

	# create a tag with the new version
	my $tag = _format_tag($self->tag_format, $self->zilla);
	my $message = _format_tag($self->tag_message, $self->zilla);
	my $tagpath = $depotpath;
	$tagpath = dirname( $tagpath ) until basename( $tagpath ) eq
		$project_dir or basename( $tagpath ) eq $depotname;;
	$tagpath .= "/$tag_dir";
	system( "svk copy $depotpath $tagpath/$tag -m $message" );
	$self->log("Tagged $tag");
}

1;


=pod

=head1 NAME

Dist::Zilla::Plugin::SVK::Tag - tag the new version

=head1 VERSION

version 0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [SVK::Tag]
    tag_format  = v%v       ; this is the default
    tag_message = v%v       ; this is the default
	project = someid        ; the default is lc $dzilla->name,
	tag_directory = tags    ; the default is 'tags', as in /$project/tags

=head1 DESCRIPTION

Once the release is done, this plugin will record this fact by creating a tag of the present branch. You can set the C<tag_message> attribute to change the message.

It also checks before the release to ensure the tag to be created doesn't already exist.  (You would have to manually delete the existing tag before you could release the same version again, but that is almost never a good idea.)

The plugin accepts the following options:

=over 4

=item * tag_format - format of the tag to apply. Defaults to C<v%v>.

=item * tag_message - format of the commit message. Defaults to C<v%v>.

=item * project - the project directory, below which typically are 'trunk', 'branches' and 'tags' subdirectories. Defaults to C<$dzilla->name>, lowercased.

=item * tag_directory - location of the tags directory, below the project directory. Defaults to C<tags>.

=back

You can use the following codes in both options:

=over 4

=item C<%{dd-MMM-yyyy}d>

The current date.  You can use any CLDR format supported by
L<DateTime>.  A bare C<%d> means C<%{dd-MMM-yyyy}d>.

=item C<%n>

a newline

=item C<%N>

the distribution name

=item C<%v>

the distribution version

=back

 -- role implementation

=over 4

=item before_release

Depotpath from second line of 'svk info'. Depotname from after first slash. Project from dist.ini, is directory under depotname.

=back

=for Pod::Coverage after_release
    before_release

=head1 AUTHOR

Dr Bean <drbean at (a) cpan dot (.) org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dr Bean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

