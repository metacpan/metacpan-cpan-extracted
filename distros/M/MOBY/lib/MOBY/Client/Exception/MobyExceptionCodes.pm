#$Id: MobyExceptionCodes.pm ,v 1.1 
# Created: 26-01-2006
# Updated: 26-01-2006

# Name of the package
package MOBY::Client::Exception::MobyExceptionCodes;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use strict;

##############
# PROTOTYPES #
##############
sub getExceptionCodeDescription($);


###########################################################
# An exception code is received by giving input and then, #
# the method retrieves itself exception description.      #
###########################################################
sub getExceptionCodeDescription($) {
	
	my ($exceptionCode) = @_;
	my ($INB_Exception) = {code => '', message => ''};
	
switch: {

# ERROR CODES DEALING WITH ANALYSIS DATA
	if ($exceptionCode == 200) { # UNKNOWN NAME: [200] "Setting input data under a non-existing name, or asking for a result using an unknown name"
		
		$INB_Exception->{code} = $exceptionCode;
		$INB_Exception->{message} = "Setting input data under a non-existing name, or asking for a result using an unknown name.";
		
	} elsif ($exceptionCode == 201) { # INPUTS INVALID: [201] "Input data are invalid; not match with its definitions, or with its dependency condition"

		$INB_Exception->{code} = $exceptionCode;
		$INB_Exception->{message} = "Input data are invalid; not match with its definitions, or with its dependency condition.";
		
	} elsif ($exceptionCode == 202) { # INPUT NOT ACCEPTED: [202] "Input data are not accepted"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Input data are not accepted.",
		};

	} elsif ($exceptionCode == 221) { # INPUT REQUIRED PARAMETER: [221] "Service require parameter X"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Service require parameter.",
		};
	
	} elsif ($exceptionCode == 222) { # INPUT INCORRECT PARAMETER: [222] "Incorrect parameter X"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Incorrect parameter.",
		};

	} elsif ($exceptionCode == 223) { # INPUT INCORRECT SIMPLE: [223] "Incorrect input in simple article"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Incorrect input in simple article.",
		};

	} elsif ($exceptionCode == 224) { # INPUT INCORRECT SIMPLENB: [224] "Service requires two or more simple articles"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Service requires two or more simple articles.",
		};

	} elsif ($exceptionCode == 225) { # INPUT INCORRECT COLLECTION: [225] "Incorrect input in collection article"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Incorrect input in collection article.",
		};

	} elsif ($exceptionCode == 226) { # INPUT EMPTY OBJECT: [226] "Empty input object"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Empty input object.",
		};

	} elsif ($exceptionCode == 231) { # INPUT EMPTY MOBYCONTENT: [231] "Empty MOBYContent"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Empty MOBYContent.",
		};

	} elsif ($exceptionCode == 232) { # INPUT EMPTY MOBYCONTENT: [232] "QueryID does not exists"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "QueryID does not exists.",
		};

	} elsif ($exceptionCode == 233) { # INPUT EMPTY MOBYDATA: [233] "Empty MOBYData"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Empty MOBYData.",
		};

# EXCEPTION CODES DEALING WITH ANALYSIS EXECUTION
	} elsif ($exceptionCode == 300) { # NOT RUNNABLE: [300] "The same job has already been executed, or the data that had been set previously do not exist or are not accessible anymore"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The same job has already been executed, or the data that had been set previously do not exist or are not accessible anymore.",
		};

	} elsif ($exceptionCode == 301) { # NOT RUNNING: [301] "A job has not yet been started"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The job has not yet been started.",
		};

	} elsif ($exceptionCode == 302) { # NOT TERMINATED: [302] "A job is not interruptible for some reason"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The job is not interruptible for some reason.",
		};

# EXCEPTION CODES DEALING WITH ANALYSIS EXECUTION
	} elsif ($exceptionCode == 400) { # NO METADATA AVAILABLE: [400] "There are no metadata available"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "There are no metadata available.",
		};

# EXCEPTION CODES DEALING WITH NOTIFICATION
	} elsif ($exceptionCode == 500) { # PROTOCOLS UNACCEPTED: [500] "Server does not agree on using any of the proposed notification protocols"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Server does not agree on using any of the proposed notification protocols.",
		};

# GENERAL EXCEPTION CODES
	} elsif ($exceptionCode == 600) { # INTERNAL PROCESSING ERROR: [600] "A generic error during internal processing"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "A generic error during internal processing.",
		};

	} elsif ($exceptionCode == 601) { # COMMUNICATION FAILURE: [601] "A generic network failure"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "A generic network failure.",
		};

	} elsif ($exceptionCode == 602) { # UNKNOWN STATE: [602] "Used when a network call expects to find an existing state but failed"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Unknown State.",
		};

	} elsif ($exceptionCode == 603) { # NOT IMPLEMENTED: [603] "Not implemented method in question"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Not implemented method in question.",
		};

# NUEVO------------------------------------------------------
# NUEVO------------------------------------------------------
	} elsif ($exceptionCode == 621) { # SERIVCE NOT AVAILABLE: [621] "Service not available"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Service not available.",
		};

# NUEVO------------------------------------------------------
# NUEVO------------------------------------------------------
	} elsif ($exceptionCode == 700) { # OK: [700] "Everything was ok"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Everything was ok.",
		};

# SERVICE INTRISIC ERRORS
	} elsif ($exceptionCode == 701) { # SERVICE INTERNAL ERROR: [701] "Specific errors from the BioMOBY service"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Specific errors from the BioMOBY service.",
		};

	} elsif ($exceptionCode == 702) { # OBJECT NOT FOUND: [702] "Object not found with the given input"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Object not found with the given input.",
		};

	} elsif ($exceptionCode == 703) { # DATA_NOT_LONGER_VALID: [703] "A sequence indentifier that has been retracted"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "A sequence indentifier that has been retracted.",
		};
	} elsif ($exceptionCode == 704) { # INPUT_BIOLOGICALLY_INVALID: [704] "The input does not make sense biologically"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The input does not make sense biologically.",
		};
	} elsif ($exceptionCode == 705) { # DATA_TRANSFORMED: [705] "The input data is transformed"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The input data is transformed.",
		};

# NUEVO------------------------------------------------------
# NUEVO------------------------------------------------------

	} elsif ($exceptionCode == 721) { # INCORRECT ARTICLE NAME: [721] "The specified name of MOBYData article is wrong or does not exist"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The specified name of MOBYData article is wrong or does not exist.",
		};

	} elsif ($exceptionCode == 722) { # INCORRECT OBJECT TYPE: [722] "Incorrect Object type from specified MOBYData article"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Incorrect Object type from specified MOBYData article.",
		};

	} elsif ($exceptionCode == 723) { # INCORRECT ARTICLENAME OBJECT: [723] "The specified article name of BioMOBY Object is wrong or does not exist"
		
		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The specified article name of BioMOBY Object is wrong or does not exist.",
		};

	} elsif ($exceptionCode == 724) { # INCORRECT NAMESPACE OBJECT: [724] "The namespace of specified BioMOBY Object is invalid"
		
		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The namespace of specified BioMOBY Object is invalid.",
		};

	} elsif ($exceptionCode == 731) { # INCORRECT ARTICLENAME OF SECONDARY: [731] "The specified name of secondary is wrong or does not exist"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The specified name of secondary is wrong or does not exist.",
		};

	} elsif ($exceptionCode == 732) { # INCORRECT DATA TYPE OF SECONDARY: [732] "Incorrect data type from specified secondary article"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "Incorrect data type from specified secondary article.",
		};

	} elsif ($exceptionCode == 733) { # INCORRECT VALUE FROM SECONDARY: [733] "The value of secondary article is invalid. It is not inside of correct range"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "The value of secondary article is invalid. It is not inside of correct range.",
		};
		
	} elsif ($exceptionCode == 734) { # INCORRECT VALUE AND DEFAULT VALUE FROM SECONDARY: [734] "There is not SECONDARY value and registered SECONDARY article has not default value"

		($INB_Exception) = {
			'code' => $exceptionCode,
			'message' => "There is not SECONDARY value and registered SECONDARY article has not default value.",
		};
	}
# NUEVO------------------------------------------------------
# NUEVO------------------------------------------------------

} # End Switch

	return ($INB_Exception->{message});
	
} # End getExceptionCodeDescription

1;


###############################
# End General Purpose Package #
###############################

__END__

=head1 NAME

MOBY::Client::Exception::MobyExceptionCodes - MobyExceptionCodes

=head1 DESCRIPTION

Library that contains structure of exception codes and exception descriptions

=head1 AUTHORS

Jose Manuel Rodriguez Carrasco -jmrodriguez@cnio.es- (INB-CNIO)

=head1 METHODS

=head2 getExceptionCodeDescription

B<Function:> An exception code is received given as input. The method retrieves the exception description. For more information, see below tables and  BioMoby exception protocol.

B<Args:> Number of exception code.

B<Returns:> Description of exception given as input.

=head1 Description of exception codes

=head3 Exception codes dealing with analysis data

=begin html

	<table align="center" bgcolor="#7b7b7b" border="1" cellpadding="5" cellspacing="0" width="80%">
	<tbody>
		<tr class="tableHead" valign="top">
			<td ><b>Code</b></td>
			<td><b>Name</b></td>
			<td><b>Description</b></td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>200</td>
			<td>UNKNOWN_NAME</td>
			<td>Setting input data under a non-existing name, or asking for a result using an unknown name</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>201</td>
			<td>INPUTS_INVALID</td>
			<td>Input data are invalid; they do not match with their definitions, or with their dependency conditions</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>202</td>
			<td>INPUT_NOT_ACCEPTED</td>
			<td>Input data are not accepted</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>221</td>
			<td>INPUT_REQUIRED_PARAMETER</td>
			<td>Service require parameter X</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>222</td>
			<td>INPUT_INCORRECT_PARAMETER</td>
			<td>Incorrect parameter X</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>223</td>
			<td>INPUT_INCORRECT_SIMPLE</td>
			<td>Incorrect input in simple article</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>224</td>
			<td>INPUT_INCORRECT_SIMPLENB</td>
			<td>Service requires two or more simple articles</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>225</td>
			<td>INPUT_INCORRECT_COLLECTION</td>
			<td>Incorrect input in collection article</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>226</td>
			<td>INPUT_EMPTY_OBJECT</td>
			<td>Empty input object</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>231</td>
			<td>INPUT_EMPTY_MOBYCONTENT</td>
			<td>Empty MOBYContent</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>232</td>
			<td>INPUT_INCORRECT_MOBYDATA</td>
			<td>QueryID does not exists</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>233</td>
			<td>INPUT_EMPTY_MOBYDATA</td>
			<td>Empty MOBYData</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>233</td>
			<td>INPUT_EMPTY_MOBYDATA</td>
			<td>Empty MOBYData</td>
		</tr>

	</tbody>
	</table>

=end html

=head3 Exception codes dealing with analysis execution

=begin html

	<table align="center" bgcolor="#7b7b7b" border="1" cellpadding="5" cellspacing="0" width="80%">
	<tbody>
		<tr class="tableHead" valign="top">
			<td ><b>Code</b></td>
			<td><b>Name</b></td>
			<td><b>Description</b></td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>300</td>
			<td>NOT_RUNNABLE</td>
			<td>The same job has already been executed, or the data that had been set previously do not exist or are not accessible anymore</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>301</td>
			<td>NOT_RUNNING</td>
			<td>The job has not yet been started</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>302</td>
			<td>NOT_TERMINATED</td>
			<td>The job is not interruptible for some reason</td>
		</tr>

	</tbody>
	</table>

=end html

=head3 Error codes dealing with analysis metadata

=begin html

	<table align="center" bgcolor="#7b7b7b" border="1" cellpadding="5" cellspacing="0" width="80%">
	<tbody>
		<tr class="tableHead" valign="top">
			<td ><b>Code</b></td>
			<td><b>Name</b></td>
			<td><b>Description</b></td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>400</td>
			<td>NO_METADATA_AVAILABLE</td>
			<td>There are no metadata available</td>
		</tr>
	</tbody>
	</table>

=end html

=head3 Error codes dealing with notification

=begin html

	<table align="center" bgcolor="#7b7b7b" border="1" cellpadding="5" cellspacing="0" width="80%">
	<tbody>
		<tr class="tableHead" valign="top">
			<td ><b>Code</b></td>
			<td><b>Name</b></td>
			<td><b>Description</b></td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>500</td>
			<td>PROTOCOLS_UNACCEPTED</td>
			<td>Server does not agree on using any of the proposed notification protocols</td>
		</tr>
	</tbody>
	</table>

=end html

=head3 General error codes

=begin html

	<table align="center" bgcolor="#7b7b7b" border="1" cellpadding="5" cellspacing="0" width="80%">
	<tbody>
		<tr class="tableHead" valign="top">
			<td ><b>Code</b></td>
			<td><b>Name</b></td>
			<td><b>Description</b></td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>600</td>
			<td>INTERNAL_PROCESSING_ERROR</td>
			<td>A generic error during internal processing</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>601</td>
			<td>COMMUNICATION_FAILURE</td>
			<td>A generic network failure</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>602</td>
			<td>UNKNOWN_STATE</td>
			<td>Unknown State</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>603</td>
			<td>NOT_IMPLEMENTED</td>
			<td>Not implemented method in question</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>621</td>
			<td>SERIVCE_NOT_AVAILABLE</td>
			<td>Service not available</td>
		</tr>
	</tbody>
	</table>

=end html

=head3 Service intrinsic errors

=begin html

	<table align="center" bgcolor="#7b7b7b" border="1" cellpadding="5" cellspacing="0" width="80%">
	<tbody>
		<tr class="tableHead" valign="top">
			<td ><b>Code</b></td>
			<td><b>Name</b></td>
			<td><b>Description</b></td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>700</td>
			<td>OK</td>
			<td>Everything was ok</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>701</td>
			<td>SERVICE_INTERNAL_ERROR</td>
			<td>Specific errors from the BioMOBY service</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>702</td>
			<td>OBJECT_NOT_FOUND</td>
			<td>Object not found with the given input</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>703</td>
			<td>DATA_NOT_LONGER_VALID</td>
			<td>A sequence indentifier that has been retracted</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>704</td>
			<td>INPUT_BIOLOGICALLY_INVALID</td>
			<td>The input does not make sense biologically</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>705</td>
			<td>DATA_TRANSFORMED</td>
			<td>The input data is transformed</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>721</td>
			<td>INCORRECT_ARTICLE_NAME</td>
			<td>The specified name of MOBYData article is wrong or does not exist</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>722</td>
			<td>INCORRECT_OBJECT_TYPE</td>
			<td>Incorrect Object type from specified MOBYData article</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>723</td>
			<td>INCORRECT_ARTICLENAME_OBJECT</td>
			<td>The specified article name of BioMOBY Object is wrong or does not exist</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>724</td>
			<td>INCORRECT_NAMESPACE_OBJECT</td>
			<td>The namespace of specified BioMOBY Object is invalid</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>731</td>
			<td>INCORRECT_ARTICLENAME_SECONDARY</td>
			<td>The specified name of secondary is wrong or does not exist</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>732</td>
			<td>INCORRECT_DATA_TYPE_SECONDARY</td>
			<td>Incorrect data type from specified secondary article</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>733</td>
			<td>INCORRECT_VALUE_SECONDARY</td>
			<td>The value of secondary article is invalid. It is not inside of correct range</td>
		</tr>
		<tr align="left" valign="top" bgcolor="#eeeeee">
			<td>734</td>
			<td>INCORRECT_VALUE_AND_DEFAULTVALUE_SECONDARY</td>
			<td>There is not SECONDARY value and registered SECONDARY article has not default value</td>
		</tr>

	</tbody>
	</table>

=end html

=cut

