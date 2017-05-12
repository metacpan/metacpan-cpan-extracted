package  MetaStore::Cmetatags;

=head1 NAME

MetaStore::Cmetatags - class for collections of data, stored in database.

=head1 SYNOPSIS

    use MetaStore::Cmetatags;
    my $props = new MetaStore::Cmetatags::
      dbh   => $dbh,
      table => 'metatags',
      field => 'mid';

=head1 DESCRIPTION

Class for collections of data, stored in database.

=head1 METHODS

=cut

use strict;
use warnings;
use Data::Dumper;
use Collection::AutoSQLnotUnique;
use Collection::AutoSQL;
our @ISA = qw(Collection::AutoSQLnotUnique);
our $VERSION = '0.1';

sub after_load {
    my $self = shift;
    my %attr;
  
    foreach my $rec (@_) {
        my ( $name, $val ) = @{$rec}{qw/tname tval/};
        unless ( exists $attr{$name} ) {
            $attr{$name} = $val;
        }
        else {
            if ( ref( $attr{$name} ) ) {
                push @{ $attr{$name} }, $val;
            }
            else {
                $attr{$name} = [ $attr{$name}, $val ];
            }
        }
    }
    return \%attr;
}

sub before_save {
    my $self = shift;
    my $attr = shift;
    my @res;
    my $field      = $self->_key_field;
    my $key = delete $attr->{ $field };
    while ( my ( $name, $val ) = each %$attr ) {
        push @res,
          map { { tname => $name, tval => $_, $field=>$key } } ref($val) ? @$val : ($val);
    }
    return \@res;
}

sub _prepare_record {
    my $self = shift;
    return $self->Collection::AutoSQL::_prepare_record(@_);
}

=head1 _get_ids_by_attr

    usage:
        _get_ids_by_attr({
            __class=>'_metastore_user',
            login=>'test'
            })
=cut

sub _get_ids_by_attr {
    my $self = shift;
    my ( $attr, %opt ) = @_;
    my $dbh        = $self->_dbh;
    my $table_name = $self->_table_name();
    my $where      = join " or ", map {
        '( tname in ('
          . $dbh->quote($_)
          . ') and tval LIKE ('
          . $dbh->quote( $attr->{$_} ) . ') )'
    } keys %$attr;
    my $count = scalar keys %$attr;
    my $sql   = qq/ 
    select mid 
    from $table_name
    where $where
    group by mid HAVING ( count(*) = $count)/;
    if ( my $orderby = $opt{orderby} ) {
        $sql = qq/
            select mid, tval from $table_name
            where tname  like ('$orderby') and
            mid in ( $sql ) order by tval
        /;
        $sql .= ' DESC' if $opt{desc};
    }
    if ( my $page = $opt{page} and my $onpage = $opt{onpage} ) {
        $sql .= " limit " . ( ( $page - 1 ) * $onpage ) . ",$onpage";
    }
    my $qrt = $self->_query_dbh($sql);
    my %res = ();
    while ( my $rec = $qrt->fetchrow_hashref ) {
        $res{ $rec->{mid} }++;
    }
    $qrt->finish;
    return [ keys %res ];
}
1;
__END__

=head1 SEE ALSO

MetaStore, Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

