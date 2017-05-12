<?php  /* ------ exemple de client CAS écrit en PHP --------*/
  //include_once('CAS.php');
  //print( "Content-type: text/html\n" );
  //print( "\n" );
  // localisation du serveur CAS
  define('CAS_BASE','http://authen.demo.net');

  // propre URL
  //$service = 'http://' . $_SERVER['SERVER_NAME'] . $_SERVER['REQUEST_URI'];
  
  $service = 'http://' . $_SERVER['SERVER_NAME'] . '/castete.php';
  
  /** Cette simple fonction réalise l?authentification CAS.
   * @return  le login de l?utilisateur authentifié, ou FALSE.
   */
  function authenticate() {
      global $service ;

      // récupération du ticket (retour du serveur CAS)
      if (!isset($_GET['ticket'])) {
          // pas de ticket : on redirige le navigateur web vers le serveur CAS
          header('Location: ' . CAS_BASE . '/cas/login?service='  . $service);
          exit() ;
      }
      
      // un ticket a été transmis, on essaie de le valider auprès du serveur CAS
      $ticket  = $_GET['ticket'];
     // $service = $_GET['service'];
     
      print( 'service: '.$service.'<br>' );
      print( 'ticket: '.$ticket.'<br>' );
      //$ticket .= '1';
      $fpage = fopen (CAS_BASE . '/cas/serviceValidate?service='
                               . preg_replace('/&/','%26',$service) . '&ticket=' . $ticket,  'r');
      if ($fpage) {
          while (!feof ($fpage)) { $page .= fgets ($fpage, 1024); }
          // analyse de la réponse du serveur CAS
          print( 'la:  '.$page );
          if (preg_match('|<cas:authenticationSuccess>.*</cas:authenticationSuccess>|mis',$page)) {
              if(preg_match('|<cas:user>(.*)</cas:user>|',$page,$match)){
                  return($match[1]);
              }
          }
      }
      // problème de validation
      return FALSE;
  }

  //print( 'je passe ici' );
  $login = authenticate();

  if ($login == FALSE ) {
      echo 'Requête non authentifiée (<a href="'.$service.'"><b>Recommencer</b></a>).';
      exit() ;
  }


  // à ce point, l?utilisateur est authentifié
  echo 'Utilisateur connecté : ' . $login . '(<a href="' . CAS_BASE . '/cas/logout"><b>déconnexion</b></a>)';
?>
