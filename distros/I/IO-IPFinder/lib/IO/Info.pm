package IO::Info;

use 5.026001;
use strict;
use warnings;
use Data::Dumper;


sub new {
    my ($class, @items) = @_;
    my $self = {};

    for my $rec (@items){
      my ($key, $value);
      while (($key, $value) = each %{$rec}){
         $self->{$key} = $value
      }
    }


    bless $self, $class;

    return $self;
}


1;
__END__
