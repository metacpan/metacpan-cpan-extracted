
###############################################################################
# argument parser

get_arg_resume() {
	local arg="$1"

	case $arg in

		resume=*)
			RESUME=${arg#resume=}
			;;

		swsusp)
			SWSUSP=nonempty
			;;

	esac

}

import_handler get_arg_resume

