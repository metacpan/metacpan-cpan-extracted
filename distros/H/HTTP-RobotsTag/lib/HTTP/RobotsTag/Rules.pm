# $Id: /mirror/perl/HTTP-RobotsTag/trunk/lib/HTTP/RobotsTag/Rules.pm 31673 2007-12-09T23:59:12.668743Z daisuke  $

package HTTP::RobotsTag::Rules;
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

sub can_snippet
{
    my $self = shift;
    my $dir  = $self->{directives};
    return ! $dir->{nosnippet} && ! $dir->{none};
}

sub is_available
{
    my $self = shift;
    my $dt   = shift;

    my $limit = $self->{directives}->{unavailable_after};
    if ($limit) {
        return $dt->compare($limit) <= 0;
    }
    return 1;
}

1;

__END__

=head1 NAME

HTTP::RobotsTag::Rules - A Representation Of Robots Exclusion Rules

=head1 SYNOPSIS

  $rules = $p->parse_rules($html);
  $bool  = $rules->can_index();
  $bool  = $rules->can_follow();
  $bool  = $rules->can_archive();
  $bool  = $rules->can_snippet();
  $bool  = $rules->is_available( $dt );

=head1 DESCRIPTION

HTTP::RobotsTag::Rules represents the robots exclusion policies that are
described within HTTP headers.

=head1 METHODS

=head2 new

=head2 can_index

=head2 can_follow

=head2 can_archive

=head2 can_snippet

=head2 is_available($dt)

Returns true if the resource is available on $dt.

=cut
