package Log::Analyze;

use strict;
use warnings;
use Carp;

our $VERSION = '0.00002';

sub new {
    my $class = shift;

    return bless {
        tree      => {},
        matrix    => [],
        node_name => [],
    }, $class;
}

sub analyze {
    my $self    = shift;
    my $nodes   = shift;
    my $command = shift;

    $command ||= 'count';
    my $eval = q|$self->{tree}|;
    for (@$nodes) {
        $_ ||= "";
        $eval .= q|->{'| . $_ . q|'}|;
    }
    if ( $command eq 'count' ) {
        $eval .= q|++|;
    }
    if ( $command eq 'sum' ) {
        my $num = shift;
        if ( !$num ) {
            carp("'sum' needs one numeric parameter");
            $num = 0;
        }
        $eval .= q|+=| . $num;
    }
    if ( ref($command) eq 'CODE' ) {
        my $result = $command->( $nodes, shift );
        $result = quotemeta($result);
        $eval .= q|='| . $result . q|'|;
    }
    eval $eval;
}

sub tree {
    my $self = shift;
    return $self->{tree};
}

sub matrix {
    my $self = shift;
    $self->_walk_tree( $self->{tree} );
    my @sorted =
      sort { join( ' ', @$a ) cmp join( ' ', @$b ) } @{ $self->{matrix} };
    return \@sorted;
}

sub _walk_tree {
    my $self = shift;
    my $node = shift;

    my $node_name = $self->{node_name};
    while ( my ( $key, $value ) = each %$node ) {
        push @$node_name, $key;
        if ( ref($value) eq 'HASH' ) {
            $self->_walk_tree($value);
            pop @$node_name;
        }
        else {
            push @{ $self->{matrix} }, [ @$node_name, $value ];
            pop @$node_name;
        }
    }
}

1;
__END__

=head1 NAME

Log::Analyze -

=head1 SYNOPSIS

=head2 default pattern(count up)

  use Log::Analyze;
  
  my $parser = Log::Analyze->new;
  
  #----------------
  # count 
  #----------------
  while(<LOG>){
      chomp $_;
      my @f = split(/\t/, $_);
      $parser->analyze([$f[1],$[2],$f[3]...], "count");
  }
  
  my $hash_ref  = $parser->tree;
  my $array_ref = $parser->matrix;

=head2 sum pattern(count up)

  #----------------
  # sum
  #----------------
  while(<LOG>){
      chomp $_;
      my @f = split(/\t/, $_);
      $parser->analyze([$f[1],$[2],$f[3]...], "sum" => $f[10]);
  }

=head2 custom pattern(set coderef)

  #----------------
  # custom  
  #----------------
  while(<LOG>){
      chomp $_;
      my @f = split(/\t/, $_);
      $parser->analyze([$f[1],$[2],$f[3]...], $coderef => $argsref);
  }
  
  $code = sub {
      my $tree_data = shift;
      my $args_ref  = shift;
      ....
  };

=head1 DESCRIPTION

Log::Analyze is simple log analysis module.

Usually, a task of log analysis is simply "count" the records, 
or "sum" the value of a particular field in every log records.

Furthermore, you sometimes expect more difficult practice that become your custom code.

It makes these tasks very simple.

=head1 METHODS

=head2 new()

=head2 analyze()

=head2 tree()

=head2 matrix()

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
