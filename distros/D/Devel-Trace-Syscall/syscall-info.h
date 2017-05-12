#ifndef SYSTRACE_SYSCALL_INFO_H
#define SYSTRACE_SYSCALL_INFO_H

#include <stdint.h>

struct syscall_info {
    uint16_t syscall_no;
    intptr_t return_value;
    intptr_t args[6];
};

struct user;

void syscall_info_from_user(struct user *userdata, struct syscall_info *info);

#endif
