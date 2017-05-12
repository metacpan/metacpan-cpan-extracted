=head1 NAME

Mac::Components - Macintosh Toolbox Interface to the Components Manager

=head1 SYNOPSIS

	use Mac::Components;
	RegisterComponentResource($Resource, 1);
	OpenComponent($Component);
	CloseComponent($Component);

=head1 DESCRIPTION

=cut

use strict;

package Mac::Components;

BEGIN {
	use Exporter;
	use DynaLoader;
	
	use vars qw(@ISA @EXPORT $VERSION);
	$VERSION = '1.05';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		RegisterComponentResource
		UnregisterComponent
		FindNextComponent
		CountComponents
		GetComponentInfo
		GetComponentListModSeed
		OpenComponent
		CloseComponent
		GetComponentInstanceError
		ComponentFunctionImplemented
		SetDefaultComponent
		OpenDefaultComponent
		RegisterComponentResourceFile
		
		kAppleManufacturer
		kComponentResourceType
		kAnyComponentType
		kAnyComponentSubType
		kAnyComponentManufacturer
		kAnyComponentFlagsMask
		kComponentOpenSelect
		kComponentCloseSelect
		kComponentCanDoSelect
		kComponentVersionSelect
		kComponentRegisterSelect
		kComponentTargetSelect
		kComponentUnregisterSelect
		defaultComponentIdentical
		defaultComponentAnyFlags
		defaultComponentAnyManufacturer
		defaultComponentAnySubType
		defaultComponentAnyFlagsAnyManufacturer
		defaultComponentAnyFlagsAnyManufacturerAnySubType
		registerComponentGlobal
		registerComponentNoDuplicates
		registerComponentAfterExisting
	);
}

bootstrap Mac::Components;

=head2 Constants

=over 4

=cut

=item kAppleManufacturer

=item kComponentResourceType

=item kAnyComponentType

=item kAnyComponentSubType

=item kAnyComponentManufacturer

=item kAnyComponentFlagsMask

Default values for C<GetDefaultComponent()>.

=cut
sub kAppleManufacturer ()          {     'appl'; }
sub kComponentResourceType ()      {     'thng'; }
sub kAnyComponentType ()           {          0; }
sub kAnyComponentSubType ()        {          0; }
sub kAnyComponentManufacturer ()   {          0; }
sub kAnyComponentFlagsMask ()      {          0; }

=item defaultComponentIdentical

=item defaultComponentAnyFlags

=item defaultComponentAnyManufacturer

=item defaultComponentAnySubType

=item defaultComponentAnyFlagsAnyManufacturer

=item defaultComponentAnyFlagsAnyManufacturerAnySubType

Flags for C<GetDefaultComponent()>.

=cut
sub defaultComponentIdentical ()   		{          0; }
sub defaultComponentAnyFlags ()    		{          1; }
sub defaultComponentAnyManufacturer ()	{          2; }
sub defaultComponentAnySubType ()  		{          4; }
sub defaultComponentAnyFlagsAnyManufacturer () { (defaultComponentAnyFlags + defaultComponentAnyManufacturer); }
sub defaultComponentAnyFlagsAnyManufacturerAnySubType () { (defaultComponentAnyFlags + defaultComponentAnyManufacturer + defaultComponentAnySubType); }

=item kComponentOpenSelect

=item kComponentCloseSelect

=item kComponentCanDoSelect

=item kComponentVersionSelect

=item kComponentRegisterSelect

=item kComponentTargetSelect

=item kComponentUnregisterSelect

Standard component selectors.

=cut
sub kComponentOpenSelect ()        {         -1; }
sub kComponentCloseSelect ()       {         -2; }
sub kComponentCanDoSelect ()       {         -3; }
sub kComponentVersionSelect ()     {         -4; }
sub kComponentRegisterSelect ()    {         -5; }
sub kComponentTargetSelect ()      {         -6; }
sub kComponentUnregisterSelect ()  {         -7; }


=item registerComponentGlobal

=item registerComponentNoDuplicates

=item registerComponentAfterExisting

Flags for C<SetDefaultComponent()>.

=back

=cut
sub registerComponentGlobal ()     	  {          1; }
sub registerComponentNoDuplicates ()  {          2; }
sub registerComponentAfterExisting () {          4; }

=include Components.xs

=head1 AUTHOR

Written by Matthias Ulrich Neeracher E<lt>neeracher@mac.comE<gt>,
documentation by Bob Dalgleish E<lt>bob.dalgleish@sasknet.sk.caE<gt>.
Currently maintained by Chris Nandor E<lt>pudge@pobox.comE<gt>.

=cut
1;

__END__
