# $Id: /mirror/perl/HTML-RobotsMETA/trunk/lib/HTML/RobotsMETA/Rules.pm 3528 2007-10-16T09:36:47.480863Z daisuke  $

package HTML::RobotsMETA::Rules;
use strict;
use warnings;

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = bless { directives => \%args }, $class;
    return $self;
}

sub can_index
{
    my $self = shift;
    my $dir  = $self->{directives};
    return ! $dir->{noindex} && ! $dir->{none};
}

sub can_follow
{
    my $self = shift;
    my $dir  = $self->{directives};
    return ! $dir->{nofollow} && ! $dir->{none};
}

sub can_archive
{
    my $self = shift;
    my $dir  = $self->{directives};
    return ! $dir->{noarchive} && ! $dir->{none};
}

sub can_serve
{
    my $self = shift;
    my $dir  = $self->{directives};
    return ! $dir->{serve} && ! $dir->{none};
}

sub can_imageindex
{
    my $self = shift;
    my $dir  = $self->{directives};
    return ! $dir->{noimageindex} && ! $dir->{none};
}

sub can_imageclick
{
    my $self = shift;
    my $dir  = $self->{directives};
    return ! $dir->{noimageclick} && ! $dir->{none};
}

1;

__END__

=head1 NAME

HTML::RobotsMETA::Rules - A Representation Of Robots Exclusion Rules

=head1 SYNOPSIS

  $rules = $p->parse_rules($html);
  $bool  = $rules->can_index();
  $bool  = $rules->can_follow();
  $bool  = $rules->can_archive();
  $bool  = $rules->can_serve();
  $bool  = $rules->can_imageindex();
  $bool  = $rules->can_imageclick();

=head1 DESCRIPTION

HTML::RobotsMETA::Rules represents the robots exclusion policies that are
described within HTML META tags.

=head1 METHODS

=head2 new

=head2 can_index

=head2 can_follow

=head2 can_archive

=head2 can_serve

=head2 can_imageindex

=head2 can_imageclick

=cut
