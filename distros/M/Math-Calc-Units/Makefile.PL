use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Math::Calc::Units',
    'VERSION_FROM' => 'Units.pm', # finds $VERSION
    'EXE_FILES' => [ 'script/ucalc' ],
    'XS' => {},
);

package MY;

sub metafile {
    my ($self) = @_;

    my $out = $self->SUPER::metafile_target();
    my @extra = $self->echo(<<"END", 'META.yml', 'append');
license:      perl
recommends:
  Time::Local: 0
END
$out .= "\t$_\n" foreach (@extra);
    return $out;
}
