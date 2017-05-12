use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Gtk2::Ex::Spinner',
    AUTHOR        => 'Lukasz Strzelecki <strzelec@rswsystems.pl>',
    VERSION_FROM  => 'lib/Gtk2/Ex/Spinner.pm',
	ABSTRACT	  => 'Integer entry widget using spin button.',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Scalar::Util'			=> 0,
        'Glib::Ex::SignalIds'	=> 0,
        'Gtk2::Ex::WidgetBits'	=> 0,
    },
);
