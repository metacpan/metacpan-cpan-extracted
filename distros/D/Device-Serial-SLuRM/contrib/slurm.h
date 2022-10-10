#ifndef __SLURM_H__
#define __SLURM_H__

#include <stdint.h>

/* API */

void slurm_reset(void);

void slurm_notify(uint8_t b[], uint8_t len);
void slurm_respond(uint8_t seqno, uint8_t b[], uint8_t len);
void slurm_responderr(uint8_t seqno, uint8_t b[], uint8_t len);

/* Event handlers:
 * User code may provide implementations of either of these, to be informed
 * of incoming packets
 */
void on_slurm_notify(uint8_t b[], uint8_t len);
void on_slurm_request(uint8_t seqno, uint8_t b[], uint8_t len);

/* Background task management:
 * User code must provide on_slurm_need_tasks()
 *           must call slurm_do_tasks() at some suitable point afterwards when
 *             the serial port may be freely accessed
 */
void on_slurm_need_tasks(void);
void slurm_do_tasks(void);

/* Serial port abstraction:
 * User code must provide do_slurm_send()
 *           must call isr_slurm_recv() on receipt of bytes
 */
void do_slurm_send(uint8_t b);
void isr_slurm_recv(uint8_t b);

#endif
