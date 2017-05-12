package Devel::StackBlech::Install::Files;

$self = {
          'inc' => '',
          'typemaps' => [],
          'deps' => [],
          'libs' => ''
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/Devel/StackBlech/Install/Files.pm") {
			$CORE = $_ . "/Devel/StackBlech/Install/";
			last;
		}
	}

1;
