package Lingua::PTD::Dumper;
$Lingua::PTD::Dumper::VERSION = '1.16';
use warnings;
use strict;

use Cwd 'abs_path';
use parent 'Lingua::PTD';

=encoding UTF-8

=head1 NAME

Lingua::PTD::Dumper - Sub-module to handle PTD files in Dumper Format

=head1 SYNOPSIS

  use Lingua::PTD;

  $ptd = Lingua::PTD->new( "file.dmp" );

=head1 DESCRIPTION

Check L<<Lingua::PTD>> for complete reference.

=head1 SEE ALSO

NATools(3), perl(1)

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2014 by Alberto Manuel Brandão Simões

=cut

sub new {
  my ($class, $filename) = @_;
  
    my $self = do(abs_path($filename));
    bless $self => $class #amen
}

sub _save {
    my ($self, $filename) = @_;

    open OUT, ">:utf8", $filename or return 0;
    select OUT;
    $self->dump;
    close OUT;

    return 1;
}

"This isn't right.  This isn't even wrong.";
__END__
