package NRoffTesting;

use strict;
use warnings;
use Carp;
use File::Temp 'tempdir';

use HTML::FormatNroff::Sub;
use HTML::Parse;
use File::Path;
use Test::More;

sub new {
    my ( $class, %attr ) = @_;
    $attr{project} ||= 'test';
    $attr{directory} = tempdir( CLEANUP => 1 );
    return bless \%attr, $class;
}

sub directory {
    my ( $self, $value ) = @_;
    $self->{directory} = $value;
}

sub create_files {
    my ( $self, $actual ) = @_;

    my $dir = $self->{'directory'};

    open( my $in, '>', "$dir/$self->{name}_actual.out" );
    print $in $actual;
    close($in);

    open( my $out, '>', "$dir/$self->{name}_expected.out" );
    print $out $self->{'expected'};
    close($out);

    unless ( $self->{html_file} ) {
        open( my $html, '>', "$dir/$self->{name}.html" );
        print $html $self->{'html_source'};
        close($html);
    }
}

sub run_test {
    my ($self) = @_;

    my $html;

    if ( $self->{'html_file'} ) {
        note "Using file $self->{html_file}";
        $html = parse_htmlfile( $self->{html_file} );
    }
    else {
        $html = parse_html( $self->{html_source} );
    }

    unless ($html) {
        fail "No HTML?";
        return;
    }

    my $formatter = HTML::FormatNroff::Sub->new(
        name       => $self->{name},
        project    => $self->{project},
        man_date   => $self->{man_date},
        man_header => $self->{man_header}
    );
    my $actual = $formatter->format($html);

    $self->create_files($actual);

    is shrink($actual), shrink( $self->{expected} );
}

sub shrink {
    my $text = @_;
    $text =~ s/\s+//g;
}

1;
