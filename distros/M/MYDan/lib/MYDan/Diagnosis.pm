package MYDan::Diagnosis;
use warnings;
use strict;

sub new
{
    my ( $class, %self ) = @_;
    map{
        die "$_ defined error" unless $self{$_} && $self{$_} =~ /^[a-zA-Z0-9_:\-]+$/
    }qw( os arch );
    bless \%self, ref $class || $class;
}

sub run
{
    my ( $this, $path, $x ) = splice @_, 0, 2;
    die "path undef" unless defined $path;

    map { $x += -f $_ ? $this->do( $_ ) : $this->run( $_ ); }glob "$path/*";
    return $x;
}

sub do
{
    my ( $this, $path ) = @_;

    die "path undef" unless defined $path;

    my $title = $path; $title =~ s#.*/plugin/code/##;
    print "=" x 75, "\n$title\n";

    my $temp = $path;
    $temp =~ s#/plugin/code/#/plugin/$this->{os}/$this->{arch}/code/#;

    my $code = do ( -f $temp ? $temp : $path );
    die "load code: $path fail" unless $code && ref $code eq 'CODE';
    &$code();
}

1;
