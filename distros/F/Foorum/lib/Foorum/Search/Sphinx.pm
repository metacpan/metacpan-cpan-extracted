package Foorum::Search::Sphinx;

use Moose;
our $VERSION = '1.001000';
use Sphinx::Search;
use Foorum::SUtils qw/schema/;

has 'sphinx' => (
    is      => 'ro',
    isa     => 'Sphinx::Search',
    lazy    => 1,
    default => sub {

        # check if Sphinx is available
        # YYY? TODO, make localhost/3312 configurable
        my $sphinx = Sphinx::Search->new();
        $sphinx->SetServer( 'localhost', 3312 );
        return $sphinx;
    }
);

has 'schema' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { schema() },
);

sub can_search { return shift->sphinx->_Connect(); }

sub query {
    my ( $self, $type, $params ) = @_;

    if ( $self->can($type) ) {
        return $self->$type($params);
    } else {
        return;
    }
}

sub topic {
    my ( $self, $params ) = @_;

    my $forum_id  = $params->{'forum_id'};
    my $title     = $params->{'title'};
    my $author_id = $params->{'author_id'};
    my $date      = $params->{'date'};
    my $page      = $params->{'page'} || 1;
    my $per_page  = $params->{per_page} || 20;
    my $order_by  = $params->{order_by} || 'last_update_date';

    my $sphinx = $self->sphinx;
    $sphinx->ResetFilters();

    $sphinx->SetFilter( 'forum_id',  [$forum_id] )  if ($forum_id);
    $sphinx->SetFilter( 'author_id', [$author_id] ) if ($author_id);

    if ( $date and $date =~ /^\d+$/ ) {

        # date value would be 2, 7, 30, 999
        my $now = time();
        if ( $date == 999 ) {    # more than 30 days
            $sphinx->SetFilterRange( 'last_update_date', $now - 30 * 86400,
                $now, 1 );
        } else {
            $sphinx->SetFilterRange( 'last_update_date', $now - $date * 86400,
                $now );
        }
    }

    $order_by = 'last_update_date' if ( 'post_on' ne $order_by );
    $sphinx->SetSortMode( SPH_SORT_ATTR_DESC, $order_by );
    $sphinx->SetMatchMode(SPH_MATCH_ANY);
    $sphinx->SetLimits( ( $page - 1 ) * $per_page, $per_page,
        20 * $per_page );    # MAX is 20 pages

    my $query;
    if ($title) {
        $title = $sphinx->EscapeString($title);
        $query = "\@title $title";
    }
    my $ret = $sphinx->Query($query);

    # deal with error of Sphinx
    unless ($ret) {
        my $err = $sphinx->GetLastError;
        return { error => $err };
    }

    my @matches = @{ $ret->{matches} };
    my @topic_ids;
    foreach my $r (@matches) {
        my $topic_id = $r->{doc};
        push @topic_ids, $topic_id;
    }

    return {
        matches => \@topic_ids,
        total   => $ret->{total_found},
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 NAME

Foorum::Search::Sphinx - search Foorum by Sphinx

=head1 SYNOPSIS

  use Foorum::Search::Sphinx;
  
  my $search = new Foorum::Search::Sphinx;
  my $ret = $search->query('topic', { author_id => 1, title => 'test', page => 2, per_page => 20 } );
  # $ret would be something like:
  # 1, error, $ret is { error => $error }
  # 2, { matches => \@topic_ids, total => 30 }

=head1 DESCRIPTION

This module implements Sphinx for Foorum Search. so generally you should check L<Foorum::Search> instead.

=head1 SEE ALSO

L<Foorum::Search>, L<Foorum::Search::Database>, L<Sphinx::Search>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
