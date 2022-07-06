package Lingua::PTD::JSON;
$Lingua::PTD::JSON::VERSION = '1.17';
use warnings;
use strict;

use parent 'Lingua::PTD';
use JSON;

=encoding UTF-8

=head1 NAME

Lingua::PTD::JSON - Sub-module to export PTD to JSON

=head1 SYNOPSIS

  use Lingua::PTD;

  my $ptd = Lingua::PTD->new( $file );
  $ptd->saveAs("json", $dest, $options);

=head1 DESCRIPTION

Check L<<Lingua::PTD>> for complete reference.

=head1 SEE ALSO

NATools(3), perl(1)

=head1 AUTHOR

Alberto Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2022 by Alberto Simões

=cut


sub new {
    my ($class, $filename) = @_;

    my $contents;
    {
        local $/;
        undef $/;
        open IN, "<:utf8", $filename or return 0;
        $contents = <IN>;
        close IN;
    }

    my $self = decode_json($contents);
    bless $self => $class #amen
}

use Data::Structure::Util qw( unbless );

sub _save {
    my ($ptd, $filename) = @_;
    my $type = ref $ptd;
    # a.k.a. DAMN!
    $ptd = unbless $ptd;
    open OUT, ">:utf8", $filename or return 0;
    print OUT encode_json($ptd);
    close OUT;
    $ptd = bless $ptd, $type;

    return 1;
}

"This is Sparta!";
__END__
