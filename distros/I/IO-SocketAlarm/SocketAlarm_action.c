bool parse_actions(SV **spec, int n_spec, struct action *actions, size_t *n_actions, char *aux_buf, size_t *aux_len) {
   bool success;
   size_t action_pos= 0;
   size_t aux_pos= 0;
   int spec_i;

   // Default is one SIGALRM to self
   if (!spec || n_spec == 0) {
      if (*n_actions) {
         actions[0].op= ACT_KILL;
         actions[0].orig_idx= 0;
         actions[0].act.kill.signal= SIGALRM;
         actions[0].act.kill.pid= getpid();
      }
      action_pos++;
   }
   else for (spec_i= 0; spec_i < n_spec; spec_i++) {
      AV *action_spec;
      const char *act_name= NULL;
      STRLEN act_namelen= 0;
      SV **el;
      size_t n_el;
      pid_t common_pid;
      int common_op, common_signal;

      // Get the arrayref for the next action
      if (!(spec[spec_i] && SvROK(spec[spec_i]) && SvTYPE(SvRV(spec[spec_i])) == SVt_PVAV))
         croak("Actions must be arrayrefs");

      // Get the 'command' name of the action
      action_spec= (AV*) SvRV(spec[spec_i]);
      n_el= av_count(action_spec);
      if (n_el < 1 || !(el= av_fetch(action_spec, 0, 0)) || !SvPOK(*el))
         croak("First element of action must be a string");
      act_name= SvPV(*el, act_namelen);

      // Dispatch based on the command
      switch (act_namelen) {
      case 3:
         if (strcmp(act_name, "sig") == 0) {
            if (n_el > 2)
               croak("Too many parameters for 'sig' action");
            common_signal= (n_el == 2 && (el= av_fetch(action_spec, 1, 0)) != NULL && SvOK(*el))?
               parse_signal(*el) : SIGALRM;
            common_pid= getpid();
            goto parse_kill_common;
         }
         if (strcmp(act_name, "run") == 0) {
            common_op= ACT_RUN;
            goto parse_run_common;
         }
      case 4:
         if (strcmp(act_name, "kill") == 0) {
            if (n_el != 3)
               croak("Expected 2 parameters for 'kill' action");
            el= av_fetch(action_spec, 1, 0);
            if (!el || !SvOK(*el))
               croak("Expected Signal as first parameter to 'kill'");
            common_signal= parse_signal(*el);
            el= av_fetch(action_spec, 2, 0);
            if (!el || !SvIOK(*el))
               croak("Expected PID as second parameter to 'kill'");
            common_pid= SvIV(*el);
            goto parse_kill_common;
         }
         if (strcmp(act_name, "exec") == 0) {
            common_op= ACT_EXEC;
            goto parse_run_common;
         }
      case 5:
         if (strcmp(act_name, "sleep") == 0) {
            if (n_el != 2)
               croak("Expected 1 parameter to 'sleep' action");
            el= av_fetch(action_spec, 1, 0);
            if (!el || !SvOK(*el) || !looks_like_number(*el))
               croak("Expected number of seconds in 'sleep' action");
            if (action_pos < *n_actions) {
               actions[action_pos].op= ACT_SLEEP;
               actions[action_pos].orig_idx= spec_i;
               actions[action_pos].act.slp.seconds= SvNV(*el);
            }
            ++action_pos;
            continue;
         }
         if (strcmp(act_name, "close") == 0) {
            common_op= ACT_x_CLOSE;
            goto parse_close_common;
         }
      case 6:
         // The repeat feature opens the possibility of infinite busy-loops,
         // and probably creates more problems than it solves.
         //if (strcmp(act_name, "repeat") == 0) {
         //   int act_count= spec_i;
         //   if (!act_count)
         //      croak("'repeat' cannot be the first action");
         //   if (n_el != 1) { // default is to repeat all, via act_count=i above
         //      if (n_el != 2)
         //         croak("Expected 0 or 1 parameters to 'repeat'");
         //      el= av_fetch(action_spec, 1, 0);
         //      if (!el || !SvOK(*el) || !looks_like_number(*el) || SvIV(*el) <= 0)
         //         croak("Expected positive integer of actions to repeat");
         //      act_count= SvIV(*el);
         //   }
         //   if (action_pos < *n_actions) {
         //      int dest_act_idx, dest_spec_idx= spec_i - act_count;
         //      // Locate the first action record with orig_idx == dest_spec_idx;
         //      for (dest_act_idx= 0; dest_act_idx < spec_i; dest_act_idx++)
         //         if (actions[dest_act_idx].orig_idx == dest_spec_idx)
         //            break;
         //      actions[action_pos].op= ACT_JUMP;
         //      actions[action_pos].orig_idx= spec_i;
         //      actions[action_pos].act.jmp.idx= dest_act_idx;
         //   }
         //   ++action_pos;
         //   continue;
         //}
         if (strcmp(act_name, "shut_r") == 0) {
            common_op= ACT_x_SHUT_R;
            goto parse_close_common;
         }
         if (strcmp(act_name, "shut_w") == 0) {
            common_op= ACT_x_SHUT_W;
            goto parse_close_common;
         }
      case 7:
         if (strcmp(act_name, "shut_rw") == 0) {
            common_op= ACT_x_SHUT_RW;
            goto parse_close_common;
         }
      default:
         croak("Unknown command '%s' in action list", act_name);
      }
      if (0) parse_kill_common: { // arrive from 'kill' and 'sig'
         // common_signal, common_pid will be set.
         // Is there an available action?
         if (action_pos < *n_actions) {
            actions[action_pos].op= ACT_KILL;
            actions[action_pos].orig_idx= spec_i;
            actions[action_pos].act.kill.signal= common_signal;
            actions[action_pos].act.kill.pid= common_pid;
         }
         ++action_pos;
      }
      if (0) parse_run_common: { // arrive from 'run' and 'exec'
         char **argv= NULL, *str;
         STRLEN len;
         int j, argc= n_el-1;
         // common_op will be set.
         if (n_el < 2)
            croak("Expected at least one parameter for '%s'", act_name);
         // Align to pointer boundary within aux_buf
         aux_pos += sizeof(void*) - 1;
         aux_pos &= ~(sizeof(void*) - 1);
         // allocate an array of char* within aux_buf
         // argv remains NULL if there isn't room for it
         if (aux_pos + sizeof(void*) * n_el <= *aux_len)
            argv= (char**)(aux_buf + aux_pos);
         aux_pos += sizeof(void*) * (argc+1);
         // size up each of the strings, and copy them to the buffer if space available
         for (j= 0; j < argc; j++) {
            el= av_fetch(action_spec, j+1, 0);
            if (!el || !*el || !SvOK(*el))
               croak("Found undef element in arguments for '%s'", act_name);
            str= SvPV(*el, len);
            if (argv && aux_pos + len + 1 <= *aux_len) {
               argv[j]= aux_buf + aux_pos;
               memcpy(argv[j], str, len+1);
            }
            aux_pos += len+1;
         }
         // argv lists must end with NULL
         if (argv)
            argv[argc]= NULL;
         // store in an action if space remaining.
         if (action_pos < *n_actions) {
            actions[action_pos].op= common_op;
            actions[action_pos].orig_idx= spec_i;
            actions[action_pos].act.run.argc= argc;
            actions[action_pos].act.run.argv= argv;
         }
         ++action_pos;
      }
      if (0) parse_close_common: { // arrive from 'close', 'shut_r', 'shut_w', 'shut_rw'
         int j;
         const char *str;
         STRLEN len;
         // common_op will be set, and can be ORed with the variant
         if (n_el < 2)
            croak("Expected 1 or more parameters to '%s'", act_name);
         // Each parameter is another action_fd or action_sockname action
         for (j= 1; j < n_el; j++) {
            el= av_fetch(action_spec, j, 0);
            if (!el || !*el || !SvOK(*el))
               croak("'%s' parameter %d is undefined", act_name, j-1);
            // If not a ref...
            if (!SvROK(*el)) {
               // Is it a file descriptor integer?
               if (looks_like_number(*el)) {
                  IV fd= SvIV(*el);
                  if (fd >= 0 && fd < 0x10000) {
                     if (action_pos < *n_actions) {
                        actions[action_pos].op= common_op | ACT_FD_x;
                        actions[action_pos].orig_idx= spec_i;
                        actions[action_pos].act.fd.fd= fd;
                     }
                     ++action_pos;
                     continue;
                  }
               }
               str= SvPV(*el, len);
               // Is the length one of struct sockaddr_in, sockaddr_un, or sockaddr?
               if (len == sizeof(struct sockaddr)
                || len == sizeof(struct sockaddr_in)
                || len == sizeof(struct sockaddr_un)
               ) {
                  if (action_pos < *n_actions) {
                     actions[action_pos].op= common_op | ACT_PNAME_x;
                     actions[action_pos].orig_idx= spec_i;
                     actions[action_pos].act.nam.addr_len= len;
                     actions[action_pos].act.nam.addr= (struct sockaddr*) (aux_buf+aux_pos);
                  }
                  if (aux_pos + len <= *aux_len)
                     memcpy((aux_buf+aux_pos), str, len);
                  aux_pos += len;
                  action_pos++;
                  continue;
               }
               // TODO: parse host:port strings
            }
            else {
               // Try getting a file descriptor from the ref
               int fd= fileno_from_sv(*el);
               if (fd >= 0) {
                  if (action_pos < *n_actions) {
                     actions[action_pos].op= common_op | ACT_FD_x;
                     actions[action_pos].orig_idx= spec_i;
                     actions[action_pos].act.fd.fd= fd;
                  }
                  ++action_pos;
                  continue;
               }
               // TODO: allow notation for socket self-name like { sockname => $x }
               // and maybe allow a full pair of { sockname => $x, peername => $y }
               // or even partial matches like { port => $num }
            }
            str= SvPV(*el, len);
            croak("Invalid parameter to '%s': '%s'; must be integer (fileno), file handle, or socket name like from getpeername", act_name, str);
         }
      }
   }
   success= (action_pos <= *n_actions) && (aux_pos <= *aux_len);
   *n_actions= action_pos;
   *aux_len= aux_pos;
   return success;
}

bool execute_action(struct action *act, bool resume, struct timespec *now_ts, struct socketalarm *parent) {
   int low= act->op & 0xF;
   int high= act->op & ~0xF;
   int how;
   char msgbuf[128];

   switch (high) {
   case ACT_KILL:
      if (kill(act->act.kill.pid, act->act.kill.signal) != 0)
         perror("kill");
      return true; // move to next action
   case ACT_SLEEP: {
      lazy_build_now_ts(now_ts);
      // On initial entry to this action, use current time to calculate the wake time
      if (!resume) {
         double t_seconds;
         t_seconds= (double) now_ts->tv_sec + .000000001 * now_ts->tv_nsec;
         // Add seconds to this time
         t_seconds += act->act.slp.seconds;
         parent->wake_ts.tv_sec= (time_t) t_seconds;
         parent->wake_ts.tv_nsec= (t_seconds - (long) t_seconds) * 1000000000;
         if (!parent->wake_ts.tv_nsec)
            parent->wake_ts.tv_nsec= 1; // because using tv_nsec as a defined-test
         return false; // come back later
      }
      // Else see whether we have reached that time yet
      if (now_ts->tv_sec > parent->wake_ts.tv_sec
         || (now_ts->tv_sec == parent->wake_ts.tv_sec && now_ts->tv_nsec >= parent->wake_ts.tv_nsec))
         return true; // reached end_ts
      return false; // still waiting
   }
   //case ACT_JUMP:
   //   parent->cur_action= act->act.jmp.idx - 1; // parent will ++ after we return true
   //   return true;
   case ACT_FD_x:
      switch (low) {
      case ACT_x_SHUT_R: how= SHUT_RD; if (0)
      case ACT_x_SHUT_W: how= SHUT_WR; if (0)
      case ACT_x_SHUT_RW: how= SHUT_RDWR;
         if (shutdown(act->act.fd.fd, how) < 0) perror("shutdown");
         break;
      default:
         if (close(act->act.fd.fd) < 0) perror("close");
      }
      return true;
   case ACT_PNAME_x:
   case ACT_SNAME_x: {
      struct sockaddr_storage addr;
      socklen_t len;
      int ret, i;
      for (i= 0; i < 1024; i++) {
         len= sizeof(addr);
         ret= high == ACT_PNAME_x? getpeername(i, (struct sockaddr*)&addr, &len)
                                 : getsockname(i, (struct sockaddr*)&addr, &len);
         if (ret == 0 && len == act->act.nam.addr_len
            && memcmp(act->act.nam.addr, &addr, len) == 0
         ) {
            switch (low) {
            case ACT_x_SHUT_R: how= SHUT_RD; if (0)
            case ACT_x_SHUT_W: how= SHUT_WR; if (0)
            case ACT_x_SHUT_RW: how= SHUT_RDWR;
               if (shutdown(i, how) < 0) perror("shutdown");
               break;
            default:
               if (close(i) < 0) perror("close");
            }
         }
      }
      return true;
   }
   case ACT_EXEC: {
      char **argv= act->act.run.argv;
      if (act->op == ACT_RUN) {
         // double-fork, so that parent can reap child, and grandchild gets cleaned up by init()
         pid_t child, gchild;
         if ((child= fork()) < 0) {       // fork failure
            perror("fork");
            return true;
         }
         else if (child > 0) {            // parent - wait for immediate child to return
            int status= -1;
            waitpid(child, &status, 0);
            if (status != 0)
               perror("waitpid");  // not accurate, but probably not going to happen unless child fails to fork
            return true;
         }
         else if ((gchild= fork()) != 0) { // second fork
            if (gchild < 0) perror("fork");
            _exit(gchild < 0? 1 : 0);       // immediately exit
         }
         // else we are the grandchild now
      }
      close(0);
      open("/dev/null", O_RDONLY);
      execvp(argv[0], argv);
      perror("exec"); // if we got here, it failed.  Log the error.
      _exit(1); // make sure we don't continue this process.
   }
   default: {
      int unused= write(2, msgbuf, snprintf(msgbuf, sizeof(msgbuf), "BUG: No such action code %d", act->op));
      (void) unused;
      return true; // pretend success; false would cause it to come back to this action later
   }}
}

const char *act_fd_variant_name(int variant) {
   switch (variant) {
   case ACT_x_CLOSE: return "close";
   case ACT_x_SHUT_R: return "shut_r";
   case ACT_x_SHUT_W: return "shut_w";
   case ACT_x_SHUT_RW: return "shut_rw";
   default: return "BUG";
   }
}

const char *act_fd_variant_description(int variant) {
   switch (variant) {
   case ACT_x_CLOSE: return "close";
   case ACT_x_SHUT_R: return "shutdown SHUT_RD";
   case ACT_x_SHUT_W: return "shutdown SHUT_WR";
   case ACT_x_SHUT_RW: return "shutdown SHUT_RDWR";
   default: return "BUG";
   }
}

static void inflate_action(struct action *act, AV *dest) {
   int low= act->op & 0xF;
   int high= act->op & ~0xF;
   int i;
   switch (high) {
   case ACT_KILL:  av_extend(dest, 2);
      av_push(dest, newSVpvs("kill"));
      av_push(dest, newSViv(act->act.kill.signal));
      av_push(dest, newSViv(act->act.kill.pid));
      return;
   case ACT_SLEEP: av_extend(dest, 1);
      av_push(dest, newSVpvs("sleep"));
      av_push(dest, newSVnv(act->act.slp.seconds));
      return;
   //case ACT_JUMP:  return snprintf(buffer, buflen, "goto %d", (int)act->act.jmp.idx);
   case ACT_FD_x:  av_extend(dest, 1);
      av_push(dest, newSVpv(act_fd_variant_name(low), 0));
      av_push(dest, newSViv(act->act.fd.fd));
      return;
   case ACT_PNAME_x: av_extend(dest, 1);
      av_push(dest, newSVpv(act_fd_variant_name(low), 0));
      av_push(dest, newSVpvn((char*)act->act.nam.addr, act->act.nam.addr_len));
      return;
   case ACT_EXEC: av_extend(dest, act->act.run.argc);
      av_push(dest, newSVpv(act->op == ACT_RUN? "run":"exec", 0));
      for (i= 0; i < act->act.run.argc; i++)
         av_push(dest, newSVpv(act->act.run.argv[i], 0));
      return;
   default:
      croak("BUG: action code %d", act->op);
   }
}

int snprint_action(char *buffer, size_t buflen, struct action *act) {
   int low= act->op & 0xF;
   int high= act->op & ~0xF;
   switch (high) {
   case ACT_KILL:  return snprintf(buffer, buflen, "kill sig=%d pid=%d", (int)act->act.kill.signal, (int) act->act.kill.pid);
   case ACT_SLEEP: return snprintf(buffer, buflen, "sleep %.3lfs", (double)act->act.slp.seconds);
   //case ACT_JUMP:  return snprintf(buffer, buflen, "goto %d", (int)act->act.jmp.idx);
   case ACT_FD_x:  return snprintf(buffer, buflen, "%s %d", act_fd_variant_description(low), act->act.fd.fd);
   case ACT_PNAME_x:
   case ACT_SNAME_x: {
      int pos= snprintf(buffer, buflen, "%s %s ",
         act_fd_variant_description(low),
         high == ACT_PNAME_x? "peername":"sockname"
      );
      return pos + snprint_sockaddr(buffer+pos, buflen > pos? buflen-pos : 0, act->act.nam.addr);
   }
   case ACT_EXEC: {
      int i, pos= snprintf(buffer, buflen, "%sexec(", act->op == ACT_RUN? "fork,fork," : "");
      for (i= 0; i < act->act.run.argc; i++) {
         pos += snprintf(buffer+pos, buflen > pos? buflen-pos : 0, "'%s',", act->act.run.argv[i]);
      }
      // if still in bounds, overwrite final character with ')'
      if (pos < buflen)
         buffer[pos-1]= ')';
      return pos;
   }
   default:
      return snprintf(buffer, buflen, "BUG: action code %d", act->op);
   }
}
