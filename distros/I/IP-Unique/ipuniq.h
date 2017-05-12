#include <string>
using namespace std;

class ipuniq {
	public:
		int add_ip(string);
		unsigned int unique(void);
		unsigned int total(void); 
		void compact(void);
		ipuniq();
		~ipuniq();

	private:

		unsigned int unique_ips;
		unsigned int total_ips;

		unsigned int* ips;
		unsigned int size;

		string work_string;
		string* ip_part_table;
		int* ip_numerical_table;
	
		bool split_ip_address(string);
		void new_ip_part_table(void);
		int is_formed_ok(void);
		bool numerify_ip_address(void);
		bool insert_ip(void);
		void clear_work_tables(void);
		void delete_ip_part_table(void);
		void delete_ip_numerical_table(void);
		void new_ip_numerical_table(void);
};
