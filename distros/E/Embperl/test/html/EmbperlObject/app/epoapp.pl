

sub init

    {
    my ($self, $r) = @_ ;

    $r    -> {initdoner} = 1 ;
    $self -> {initdonea} = 1 ;
    $self -> {initdoneb} = 2 ;

    return 0 ;
    }

