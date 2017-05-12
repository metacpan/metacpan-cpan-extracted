use Devel::Unwind;

unwind FOO;
# There's something going on here if the module returns 0
# then execution resumes in the 'or do' block of simple-require.pl
# but if I return 1 then execution resumes after the mark

# Look at the following comment in pp_die_unwind from pp_ctl.c
# ------------------------------------------------------------
# /* note that unlike pp_entereval, pp_require isn't
#  * supposed to trap errors. So now that we've popped the
#  * EVAL that pp_require pushed, and processed the error
#  * message, rethrow the error */
#
# So I guess the hack for 'require' is to patch the 2nd EVAL
# block found, that is always going to exist since our 'mark'
# creates one block and 'require' itself creates another.

0;
