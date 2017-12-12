use 5.004;
package File::HomeDir::Tiny;
$VERSION='0.01';
sub import{
 shift;
 "home"ne$_
  &&die __PACKAGE__." does not export $_ at ".join(' line ',(caller)[1,2])
        .".\n"
  for@_;
 *{caller()."'home"}=\&home;_:
}
eval'sub home(){'
 .($^Oeq Win32&&"$]"<5.016?'$ENV{HOME}||$ENV{USERPROFILE}}':'(<~>)[0]}');
@EXPORT='home';
