# -*- Perl -*-
=pod

=head1 Fair share scheduling API

IBM::LoadLeveler Fair share scheduling API

=head1 SYNOPSIS

  # Fair share scheduling API

  $rc=ll_fair_share(FAIR_SHARE_RESET|FAIR_SHARE_SAVE,$savedir,$savefile);

=head1 DESCRIPTION

The Fair share scheduling API has the following function:

This API is only available for LoadLeveler versions 3.3.0.0 and higher.

=over 4

=item ll_fair_share

=back

=over 4

=item ll_fair_share

=back

  $rc=ll_fair_share(FAIR_SHARE_RESET|FAIR_SHARE_SAVE,$savedir,$savefile);

This routine differs from the C API by not using the I<LL_fair_share_param> structure but instead taking all the parameters as input.

B<Parameters>

	Parameter    Description
	------------------------------------------------------------------------------------------
        $savedir     A directory to be used for saving a snapshot of data, used by FAIR_SHARE_SAVE
        $savefile    A previously saved file of data, used by FAIR_SHARE_RESET

=head1 SEE ALSO

L<LoadLeveler>
L<DataAccess>
L<perl>.

IBM LoadLeveler for AIX 5L: Using and Administering

=cut

int  
ll_fair_share(operation,dir,file)
     int    operation
     char  *dir
     char  *file

     CODE:
     {
	 LL_element          *errObj=NULL;
         LL_fair_share_param  param;

	 param.operation=operation;
         param.savedir=dir;
	 param.savedfile=file;

	 RETVAL=ll_fair_share(LL_API_VERSION,&errObj,&param);
	 if (RETVAL != API_OK )
	 {
	   sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	 }
     }
     OUTPUT:
         RETVAL
