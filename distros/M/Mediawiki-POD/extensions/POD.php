<?php
# POD WikiMedia extension

# (c) by Tels http://bloodgate.com 2007

# Takes text between <pod> </pod> tags, and runs it through the
# external script "podcnv", which generates an HTML from it.

$wgExtensionFunctions[] = "wfPODExtension";
 
function wfPODExtension() {
    global $wgParser;

    # register the extension with the WikiText parser
    # the second parameter is the callback function for processing the text between the tags

    $wgParser->setHook( "pod", "renderPOD" );
}

# for Special::Version:

$wgExtensionCredits['parserhook'][] = array(
	'name' => 'POD extension',
	'author' => 'Tels',
	'url' => 'http://wwww.bloodgate.com/perl/',
	'version' => 'v0.03',
);
 
# The callback function for converting the input text to HTML output
function renderPOD( $input ) {
    global $wgInputEncoding;

    if( !is_executable( "extensions/podcnv" ) ) {
	return "<strong class='error'><code>extensions/podcnv</code> is not executable</strong>";
    }

   $descriptorspec = array(
     0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
     1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
   );

  // this needs to be changed for PHP 5.x!
  $process = proc_open('extensions/podcnv', $descriptorspec, $pipes);

  $return_value = -1;
  if (is_resource($process)) {
    // $pipes now looks like this:
    // 0 => writeable handle connected to child stdin
    // 1 => readable handle connected to child stdout

    // It is important that you close any pipes before calling
    // proc_close in order to avoid a deadlock
    fwrite($pipes[0], $input);
    fclose($pipes[0]);

    while (!feof($pipes[1])) {
      $output .= fread($pipes[1],1024*8);
      }
    fclose($pipes[1]);

    $return_value = proc_close($process);

    }
  if (($return_value != 0) || (strlen($output) == 0)) {
	return "<strong class='error'>There was an error executing <code>extensions/podcnv</code></strong>. "
	. "Please try again or notify the administrator.";
  }

  return $output;
}
?>
