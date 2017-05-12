# Excellent snippet of code proferred by (Archbishop) "tilly" in response
# to someone asking how to provide fake input on STDIN.

package Tie::Input::Insertable;

sub PRINT
{
    my $self = shift;
    $self->{buffer} = join '', @_, $self->{buffer};
}

sub TIEHANDLE
{
    my ( $class, $fh ) = @_;
    bless { fh => $fh, buffer => "" }, $class;
}

sub FILENO
{
    my ( $self ) = @_;
    return fileno( $self->{fh} );
}

sub READLINE
{
    my $self = shift;
    return undef if $self->{eof};
    while ( -1 == index( $self->{buffer}, $/ ) ) {
        my $fh   = $self->{fh};
        my $data = <$fh>;
        if ( length( $data ) ) {
            $self->{buffer} .= $data;
        }
        else {
            $self->{eof} = 1;
            return delete $self->{buffer};
        }
    }
    my $pos = index( $self->{buffer}, $/ ) + length( $/ );
    return substr( $self->{buffer}, 0, $pos, "" );
}

sub EOF
{
    my $self = shift;
    $self->{eof} ||= not length( $self->{buffer} ) or $self->{fh}->eof();
}

#tie *FAKEIN, 'Tie::Input::Insertable', *STDIN;
#
#while (<FAKEIN>) {
#  print FAKEIN "Hello, world\n" if /foo/;
#  print $_;
#}

1;
