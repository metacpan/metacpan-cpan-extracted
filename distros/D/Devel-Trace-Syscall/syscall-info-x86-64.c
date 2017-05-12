#include "syscall-info.h"

#include <sys/user.h>

void
syscall_info_from_user(struct user *userdata, struct syscall_info *info)
{
    info->syscall_no   = userdata->regs.orig_rax;
    info->return_value = userdata->regs.rax;
    info->args[0]      = userdata->regs.rdi;
    info->args[1]      = userdata->regs.rsi;
    info->args[2]      = userdata->regs.rdx;
    info->args[3]      = userdata->regs.rcx;
    info->args[4]      = userdata->regs.r8;
    info->args[5]      = userdata->regs.r9;
}
